#!/usr/bin/env python3
"""Conversor CNES para recursos FHIR R4 da Fase 6.

Esta versão implementa somente os mapeamentos autorizados
em docs/mapeamento-cnes-fhir.md:

- id_estabelecimento_cnes -> Organization.identifier
- cep -> Location.address.postalCode

Os demais campos analisados permanecem fora dos recursos
FHIR desta versão conforme as decisões documentadas.
"""

from html import escape
from uuid import uuid4


CNES_SYSTEM = "https://saude.gov.br/fhir/sid/cnes"


def normalizar_texto(valor, campo):
    """Converte o valor para string e rejeita ausências explícitas."""
    if valor is None:
        raise ValueError(f"{campo}: valor ausente")

    texto = str(valor).strip()

    if texto.casefold() in {"", "nan", "none", "<na>"}:
        raise ValueError(f"{campo}: valor ausente")

    return texto


def criar_organization(cnes):
    """Cria Organization com o identificador CNES autorizado."""
    cnes = normalizar_texto(cnes, "id_estabelecimento_cnes")

    return {
        "resourceType": "Organization",
        "text": {
            "status": "generated",
            "div": (
                '<div xmlns="http://www.w3.org/1999/xhtml">'
                f"<p>Identificador CNES: {escape(cnes)}. "
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
    }


def criar_location(cep):
    """Cria Location contendo somente o CEP autorizado."""
    cep = normalizar_texto(cep, "cep")

    return {
        "resourceType": "Location",
        "text": {
            "status": "generated",
            "div": (
                '<div xmlns="http://www.w3.org/1999/xhtml">'
                f"<p>CEP: {escape(cep)}.</p>"
                "</div>"
            ),
        },
        "address": {
            "postalCode": cep,
        },
    }


def criar_bundle_estabelecimento(cnes, cep):
    """Agrupa Organization e Location em Bundle do tipo collection."""
    organization = criar_organization(cnes)
    location = criar_location(cep)

    return {
        "resourceType": "Bundle",
        "type": "collection",
        "entry": [
            {
                "fullUrl": f"urn:uuid:{uuid4()}",
                "resource": organization,
            },
            {
                "fullUrl": f"urn:uuid:{uuid4()}",
                "resource": location,
            },
        ],
    }


def main():
    """Executa a conversão de um par CNES/CEP pelo terminal."""
    import argparse
    import json
    from pathlib import Path

    parser = argparse.ArgumentParser(
        description="Gera um Bundle FHIR R4 com Organization e Location."
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
