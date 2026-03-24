#!/usr/bin/env python3

from __future__ import annotations

import sys
from datetime import datetime, timedelta
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


def parse_utc_timestamp(value: str, field_name: str, case_index: int) -> datetime:
    try:
        return datetime.strptime(value, '%Y-%m-%dT%H:%M:%S')
    except ValueError:
        fail(
            f"Step 10 batch configuration failed: case {case_index} field "
            f"'{field_name}' must use UTC format YYYY-MM-DDTHH:MM:SS."
        )


def normalized_positive_integer(value: object, field_name: str, case_index: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        fail(
            f"Step 10 batch configuration failed: case {case_index} field "
            f"'{field_name}' must be a positive integer."
        )

    if value <= 0:
        fail(
            f"Step 10 batch configuration failed: case {case_index} field "
            f"'{field_name}' must be greater than zero."
        )

    return value


def utc_suffix(utc_time: datetime) -> str:
    return utc_time.strftime('%Y_%m_%d_%H%M%S')


def emit_case_row(
    case_id: str,
    utc_value: str,
    include_keplerian: bool,
    output_filename: str,
) -> None:
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
        include_keplerian = case_definition.get('include_keplerian_elements', False)
        if not isinstance(include_keplerian, bool):
            fail(
                f"Step 10 batch configuration failed: case {case_index} field "
                "'include_keplerian_elements' must be true or false."
            )

        output_filename = optional_text(
            case_definition.get('output_filename'), 'output_filename', case_index
        )

        has_single_utc = 'utc' in case_definition and case_definition.get('utc') is not None
        has_range_fields = any(
            field_name in case_definition and case_definition.get(field_name) is not None
            for field_name in ('utc_start', 'utc_end', 'dt_seconds')
        )

        if has_single_utc and has_range_fields:
            fail(
                f"Step 10 batch configuration failed: case {case_index} must define "
                "either 'utc' or the range fields 'utc_start', 'utc_end', and "
                "'dt_seconds', but not both."
            )

        if has_single_utc:
            utc_value = normalized_text(case_definition.get('utc'), 'utc', case_index)
            emit_case_row(case_id, utc_value, include_keplerian, output_filename)
            continue

        if not has_range_fields:
            fail(
                f"Step 10 batch configuration failed: case {case_index} must define "
                "either 'utc' or the range fields 'utc_start', 'utc_end', and "
                "'dt_seconds'."
            )

        utc_start_text = normalized_text(
            case_definition.get('utc_start'), 'utc_start', case_index
        )
        utc_end_text = normalized_text(
            case_definition.get('utc_end'), 'utc_end', case_index
        )
        dt_seconds = normalized_positive_integer(
            case_definition.get('dt_seconds'), 'dt_seconds', case_index
        )

        if output_filename != '':
            fail(
                f"Step 10 batch configuration failed: case {case_index} range "
                "definitions must not set 'output_filename'; filenames are generated "
                "from the expanded timestamps."
            )

        utc_start = parse_utc_timestamp(utc_start_text, 'utc_start', case_index)
        utc_end = parse_utc_timestamp(utc_end_text, 'utc_end', case_index)

        if utc_end < utc_start:
            fail(
                f"Step 10 batch configuration failed: case {case_index} field "
                "'utc_end' must not be earlier than 'utc_start'."
            )

        total_seconds = int((utc_end - utc_start).total_seconds())
        if (total_seconds % dt_seconds) != 0:
            fail(
                f"Step 10 batch configuration failed: case {case_index} UTC range "
                "span must be an exact multiple of 'dt_seconds'."
            )

        step_delta = timedelta(seconds=dt_seconds)
        current_utc = utc_start
        while current_utc <= utc_end:
            expanded_case_id = f'{case_id}_{utc_suffix(current_utc)}'
            emit_case_row(
                expanded_case_id,
                current_utc.strftime('%Y-%m-%dT%H:%M:%S'),
                include_keplerian,
                '',
            )
            current_utc += step_delta


if __name__ == '__main__':
    main()
