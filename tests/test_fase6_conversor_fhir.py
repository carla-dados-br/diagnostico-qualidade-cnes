"""Testes do conversor CNES -> FHIR R4 da Fase 6."""

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONVERSOR_PATH = ROOT / "python" / "fase6-conversor-fhir.py"

SPEC = importlib.util.spec_from_file_location(
    "fase6_conversor_fhir",
    CONVERSOR_PATH,
)
conversor = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(conversor)


class TestValidacaoEntradas(unittest.TestCase):
    """Testa as restricoes de entrada adotadas nesta implementacao."""

    def test_cnes_valido_preserva_zero_a_esquerda(self):
        self.assertEqual(conversor.validar_cnes("0003735"), "0003735")

    def test_cnes_alfabetico_e_rejeitado(self):
        with self.assertRaisesRegex(ValueError, "formato invalido"):
            conversor.validar_cnes("abc")

    def test_cnes_com_quantidade_incorreta_de_digitos_e_rejeitado(self):
        for valor in ("123456", "12345678"):
            with self.subTest(valor=valor):
                with self.assertRaisesRegex(ValueError, "formato invalido"):
                    conversor.validar_cnes(valor)

    def test_cep_valido_e_aceito(self):
        self.assertEqual(conversor.validar_cep("07144000"), "07144000")

    def test_cep_invalido_e_rejeitado(self):
        for valor in ("12", "abcdefgh", "123456789"):
            with self.subTest(valor=valor):
                with self.assertRaisesRegex(ValueError, "formato invalido"):
                    conversor.validar_cep(valor)

    def test_ausencias_explicitas_sao_rejeitadas(self):
        for valor in (None, "", "   ", "nan", "None", "<NA>"):
            with self.subTest(valor=valor):
                with self.assertRaisesRegex(ValueError, "valor ausente"):
                    conversor.validar_cnes(valor)


class TestRecursosFHIR(unittest.TestCase):
    """Testa a estrutura minima autorizada para a Fase 6."""

    def test_organization_contem_somente_mapeamentos_autorizados(self):
        organization = conversor.criar_organization("0003735", "07144000")

        self.assertEqual(organization["resourceType"], "Organization")
        self.assertEqual(
            organization["identifier"],
            [
                {
                    "system": conversor.CNES_SYSTEM,
                    "value": "0003735",
                }
            ],
        )
        self.assertEqual(
            organization["address"],
            [{"postalCode": "07144000"}],
        )
        self.assertNotIn("type", organization)
        self.assertNotIn("partOf", organization)

    def test_bundle_contem_uma_organization_sem_location(self):
        bundle = conversor.criar_bundle_estabelecimento(
            "0003735",
            "07144000",
        )

        self.assertEqual(bundle["resourceType"], "Bundle")
        self.assertEqual(bundle["type"], "collection")
        self.assertEqual(len(bundle["entry"]), 1)
        self.assertEqual(
            bundle["entry"][0]["resource"]["resourceType"],
            "Organization",
        )

        resource_types = [
            entry["resource"]["resourceType"]
            for entry in bundle["entry"]
        ]
        self.assertNotIn("Location", resource_types)

    def test_fullurl_e_deterministico(self):
        primeiro = conversor.criar_bundle_estabelecimento(
            "0003735",
            "07144000",
        )
        segundo = conversor.criar_bundle_estabelecimento(
            "0003735",
            "07144000",
        )

        self.assertEqual(
            primeiro["entry"][0]["fullUrl"],
            segundo["entry"][0]["fullUrl"],
        )
        self.assertEqual(
            primeiro["entry"][0]["fullUrl"],
            "urn:uuid:961135f4-0746-5b1c-9775-1f243547962c",
        )

    def test_fullurl_depende_do_cnes_e_nao_do_cep(self):
        primeiro = conversor.criar_bundle_estabelecimento(
            "0003735",
            "07144000",
        )
        segundo = conversor.criar_bundle_estabelecimento(
            "0003735",
            "99999999",
        )

        self.assertEqual(
            primeiro["entry"][0]["fullUrl"],
            segundo["entry"][0]["fullUrl"],
        )


class TestCLI(unittest.TestCase):
    """Testa o tratamento das entradas pela interface de linha de comando."""

    def executar(self, cnes, cep, saida):
        return subprocess.run(
            [
                sys.executable,
                str(CONVERSOR_PATH),
                "--cnes",
                cnes,
                "--cep",
                cep,
                "--saida",
                str(saida),
            ],
            capture_output=True,
            text=True,
        )

    def test_cli_aceita_par_estruturalmente_valido(self):
        with tempfile.TemporaryDirectory() as tmp:
            saida = Path(tmp) / "bundle.json"
            resultado = self.executar(
                "0003735",
                "07144000",
                saida,
            )

            self.assertEqual(resultado.returncode, 0)
            self.assertTrue(saida.exists())

    def test_cli_rejeita_cnes_invalido_sem_criar_arquivo(self):
        with tempfile.TemporaryDirectory() as tmp:
            saida = Path(tmp) / "bundle.json"
            resultado = self.executar(
                "abc",
                "07144000",
                saida,
            )

            self.assertNotEqual(resultado.returncode, 0)
            self.assertIn("formato invalido", resultado.stderr)
            self.assertFalse(saida.exists())

    def test_cli_rejeita_cep_invalido_sem_criar_arquivo(self):
        with tempfile.TemporaryDirectory() as tmp:
            saida = Path(tmp) / "bundle.json"
            resultado = self.executar(
                "0003735",
                "12",
                saida,
            )

            self.assertNotEqual(resultado.returncode, 0)
            self.assertIn("formato invalido", resultado.stderr)
            self.assertFalse(saida.exists())


if __name__ == "__main__":
    unittest.main()
