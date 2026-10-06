#!/usr/bin/env python3
"""Conversor CNES para recursos FHIR R4 da Fase 6.

Esta versão implementa somente os mapeamentos autorizados
em docs/mapeamento-cnes-fhir.md:

- id_estabelecimento_cnes -> Organization.identifier
- cep -> Organization.address.postalCode

Os demais campos analisados permanecem fora dos recursos
FHIR desta versão conforme as decisões documentadas.
"""

import re
from html import escape
from uuid import NAMESPACE_URL, uuid5


CNES_SYSTEM = "https://saude.gov.br/fhir/sid/cnes"


def normalizar_texto(valor, campo):
    """Converte o valor para string e rejeita ausências explícitas."""
    if valor is None:
        raise ValueError(f"{campo}: valor ausente")

    texto = str(valor).strip()

    if texto.casefold() in {"", "nan", "none", "<na>"}:
        raise ValueError(f"{campo}: valor ausente")

    return texto


def validar_cnes(valor):
    """Valida a restricao de entrada CNES adotada nesta implementacao."""
    texto = normalizar_texto(valor, "id_estabelecimento_cnes")

    if re.fullmatch(r"[0-9]{7}", texto) is None:
        raise ValueError(
            "id_estabelecimento_cnes: formato invalido para esta implementacao; "
            "esperado exatamente 7 digitos numericos"
        )

    return texto


def validar_cep(valor):
    """Valida a restricao de entrada CEP adotada nesta implementacao."""
    texto = normalizar_texto(valor, "cep")

    if re.fullmatch(r"[0-9]{8}", texto) is None:
        raise ValueError(
            "cep: formato invalido para esta implementacao; "
            "esperado exatamente 8 digitos numericos"
        )

    return texto


def criar_organization(cnes, cep):
    """Cria Organization com identificador CNES e CEP autorizados."""
    cnes = validar_cnes(cnes)
    cep = validar_cep(cep)

    return {
        "resourceType": "Organization",
        "text": {
            "status": "generated",
            "div": (
                '<div xmlns="http://www.w3.org/1999/xhtml">'
                f"<p>Identificador CNES: {escape(cnes)}. CEP: {escape(cep)}. "
                f"Sistema: {escape(CNES_SYSTEM)}.</p>"
                "</div>"
            ),
        },
        "identifier": [
            {
                "system": CNES_SYSTEM,
                "value": cnes,
            }
        ],
        "address": [
            {
                "postalCode": cep,
            }
        ],
    }


def criar_bundle_estabelecimento(cnes, cep):
    """Cria Bundle do tipo collection contendo a Organization do estabelecimento."""
    organization = criar_organization(cnes, cep)
    cnes_normalizado = organization["identifier"][0]["value"]

    return {
        "resourceType": "Bundle",
        "type": "collection",
        "entry": [
            {
                "fullUrl": f"urn:uuid:{uuid5(NAMESPACE_URL, f'{CNES_SYSTEM}/{cnes_normalizado}')}",
                "resource": organization,
            },
        ],
    }


def main():
    """Executa a conversão de um par CNES/CEP pelo terminal."""
    import argparse
    import json
    from pathlib import Path

    parser = argparse.ArgumentParser(
        description=(
            "Gera um Bundle FHIR R4 com Organization contendo identificador CNES e CEP. "
            "O par CNES/CEP deve ter sua correspondencia verificada antes da chamada."
        )
    )
    parser.add_argument("--cnes", required=True, help="Identificador CNES.")
    parser.add_argument("--cep", required=True, help="CEP do estabelecimento.")
    parser.add_argument("--saida", required=True, help="Arquivo JSON de destino.")

    args = parser.parse_args()
    destino = Path(args.saida)

    if not destino.parent.is_dir():
        parser.error(f"Diretório de destino não existe: {destino.parent}")

    try:
        bundle = criar_bundle_estabelecimento(args.cnes, args.cep)
    except ValueError as erro:
        parser.error(str(erro))

    try:
        with destino.open("x", encoding="utf-8") as arquivo:
            json.dump(bundle, arquivo, ensure_ascii=False, indent=2)
            arquivo.write("\n")
    except FileExistsError:
        parser.error(f"Arquivo já existe: {destino}")

    print(f"Bundle gerado: {destino}")


if __name__ == "__main__":
    main()
