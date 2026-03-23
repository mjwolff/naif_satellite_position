#!/usr/bin/env python3

from __future__ import annotations

import sys
from pathlib import Path

import yaml


def fail(message: str) -> None:
    print(message)
    raise SystemExit(1)


def normalized_text(value: object, field_name: str, case_index: int) -> str:
    if not isinstance(value, str):
        fail(
            f"Step 10 batch configuration failed: case {case_index} field "
            f"'{field_name}' must be a string."
        )

    text_value = value.strip()
    if text_value == '':
        fail(
            f"Step 10 batch configuration failed: case {case_index} field "
            f"'{field_name}' is empty."
        )

    if any(character in text_value for character in ('\t', '\n', '\r')):
        fail(
            f"Step 10 batch configuration failed: case {case_index} field "
            f"'{field_name}' contains unsupported control characters."
        )

    return text_value


def optional_text(value: object, field_name: str, case_index: int) -> str:
    if value is None:
        return ''

    if not isinstance(value, str):
        fail(
            f"Step 10 batch configuration failed: case {case_index} field "
            f"'{field_name}' must be a string when provided."
        )

    text_value = value.strip()
    if any(character in text_value for character in ('\t', '\n', '\r')):
        fail(
            f"Step 10 batch configuration failed: case {case_index} field "
            f"'{field_name}' contains unsupported control characters."
        )

    return text_value


def main() -> None:
    if len(sys.argv) != 2:
        fail('Step 10 batch configuration failed: expected one YAML configuration path.')

    config_path = Path(sys.argv[1])
    try:
        config_data = yaml.safe_load(config_path.read_text(encoding='utf-8'))
    except FileNotFoundError:
        fail(
            'Step 10 batch configuration failed: configuration file was not found: '
            f'{config_path}'
        )
    except Exception as exc:  # pragma: no cover - surfaced for IDL diagnostics
        fail(
            'Step 10 batch configuration failed: unable to read YAML configuration: '
            f'{exc}'
        )

    if config_data is None:
        config_data = {}

    if not isinstance(config_data, dict):
        fail('Step 10 batch configuration failed: top-level YAML document must be a mapping.')

    cases = config_data.get('cases')
    if not isinstance(cases, list) or len(cases) == 0:
        fail("Step 10 batch configuration failed: top-level 'cases' must be a non-empty list.")

    for case_index, case_definition in enumerate(cases, start=1):
        if not isinstance(case_definition, dict):
            fail(
                f"Step 10 batch configuration failed: case {case_index} must be a mapping."
            )

        case_id = normalized_text(case_definition.get('case_id'), 'case_id', case_index)
        utc_value = normalized_text(case_definition.get('utc'), 'utc', case_index)

        include_keplerian = case_definition.get('include_keplerian_elements', False)
        if not isinstance(include_keplerian, bool):
            fail(
                f"Step 10 batch configuration failed: case {case_index} field "
                "'include_keplerian_elements' must be true or false."
            )

        output_filename = optional_text(
            case_definition.get('output_filename'), 'output_filename', case_index
        )

        print(
            '\t'.join(
                [
                    case_id,
                    utc_value,
                    '1' if include_keplerian else '0',
                    output_filename,
                ]
            )
        )


if __name__ == '__main__':
    main()
