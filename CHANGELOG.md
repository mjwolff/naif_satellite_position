# Changelog

## 2026-03-24
- Changed Step 10 batch execution to write one aggregate CSV per batch run, with per-case `batch_status` and `failure_message` columns and deterministic filenames derived from the batch config.
- Refactored CSV export so batch mode can reuse shared row-building and table-writing helpers while preserving optional Keplerian columns.
- Updated Step 10 tests and README examples to validate and document aggregate single-file batch output, including isolated invalid-UTC failures.
- Added `config/example_tgo_occultation_3h.yaml` as a ready-to-run 3-hour, 5-second-step TGO batch example that uses the existing `occultation_valid` output flag.
- Removed the obsolete `src/nsp_emit_batch_cases.py` helper after the batch YAML path was migrated to native IDL parsing.
- Replaced the Step 10 Python YAML batch helper with native IDL `YAML_PARSE` handling in `nsp_read_batch_cases.pro`.
- Removed the Step 1 `python3`/PyYAML prerequisite and now validate the native IDL YAML parser instead.
- 2026-03-24 11:59:38 CET commit: Add batch UTC range expansion support
- 2026-03-24 11:59:56 CET commit: Record changelog timestamp for batch range support
- 2026-03-24 12:19:16 CET commit: Replace batch Python helper with IDL YAML parser
- 2026-03-24 12:19:52 CET commit: Record changelog timestamp for IDL YAML parser
- 2026-03-24 12:26:30 CET commit: Record changelog timestamp for IDL parser follow-up
- 2026-03-24 12:50:17 CET commit: Document TGO occultation batch example
- 2026-03-24 12:50:35 CET commit: Record changelog timestamp for batch example


## 2026-03-23
- Added YAML batch support for UTC ranges using `utc_start`, `utc_end`, and `dt_seconds`, with strict expansion into deterministic per-epoch cases.
- Documented the new batch range syntax and updated sample/test batch configurations to cover valid and invalid range handling.
- 2026-03-23 12:33:32 CET commit b59e2a3: Use post-commit hook for changelog timestamps
- 2026-03-23 12:34:02 CET commit feb0227: Record hook-generated changelog timestamp
- Added root-level `nsp_setup_path.pro` so repository entrypoints share one strict `!PATH` setup routine for `src/` and optional `tests/`.
- Added `ICY_DLM_PATH` resolution precedence for validation and kernel loading: IDL keyword first, then environment variable, then the existing hardwired default path.
- Documented the new `ICY_DLM_PATH` keyword and environment-variable override behavior in `README.md`.
- 2026-03-23 12:46:14 CET commit: Add configurable ICY_DLM_PATH resolution
- 2026-03-23 12:55:29 CET commit: Add per-suite test results table
- 2026-03-23 13:03:22 CET commit: testing commit-msg script.
- 2026-03-23 18:54:42 CET commit: Add shared IDL path setup helper
- 2026-03-23 19:02:53 CET commit: Record changelog timestamp for path setup helper


## 2026-03-22
- Updated Step 9 planning so Keplerian elements can be calculated and exported optionally when explicitly requested, without making them mandatory for every run.
- Added strict Step 1 environment validation for `KERNELS_PATH`, `python3` YAML-module availability, and local ICY DLM files.
- Implemented deterministic meta-kernel resolution under `KERNELS_PATH` with default `em16_ops.tm`.
- Added a reusable cross-repo `changelog-maintainer` skill and enforced changelog maintenance in repository rules.
- Documented the direct arm64 IDL binary as the Codex sandbox debugging fallback when the canonical launcher fails its architecture probe.
- Fixed meta-kernel resolution to use deterministic candidate paths instead of the broken recursive wildcard search.
- Renamed the repository root directory from devel to naif_satellite_position and updated repository path references.
- Implemented Step 3 kernel loading with explicit ICY DLM initialization and meta-kernel-directory-aware `cspice_furnsh` execution.
- Updated the entrypoint to add the repository `src/` directory to `!PATH` automatically so it can be run after compiling only `nsp_run_pipeline.pro`.
- Renamed all repository `.pro` files and internal procedures/functions with the `nsp_` prefix.
- Implemented Step 4 time handling with strict `UTC -> ET` conversion and reusable regular ET grid generation.
- Added focused Step 4 tests for UTC conversion, regular time-grid spacing, and expected failure cases.
- Moved repository test routines into a root-level `tests/` directory and updated `nsp_run_tests.pro` to load them from there.
- Implemented Step 5 single-epoch TGO state-vector retrieval in `IAU_MARS` with aberration correction `NONE`.
- Added focused Step 5 tests for direct state-vector agreement with `cspice_spkezr` and invalid-ET failure handling.
- Split Step 5 helper and test assertion routines into autoloadable modules and kept state retrieval meta-kernel-directory-aware so relative SPICE kernel references remain usable at runtime.
- Implemented Step 6 spacecraft geometry conversion with a documented Mars mean radius of `3389.5 km`.
- Added Step 6 validation against direct `cspice_reclat` and focused geometry tests for successful conversion and invalid-state failure handling.
- Implemented Step 7 solar geometry with explicit Sun-state retrieval in `IAU_MARS` and a documented spacecraft-local solar zenith angle definition.
- Added Step 7 tests for direct Sun-state agreement with `cspice_spkezr`, solar zenith angle consistency, and invalid-state failure handling.
- Implemented Step 8 occultation geometry as the minimum-radius point on the spacecraft-to-Sun line with explicit non-occultation flagging.
- Added Step 8 tests for tangent-point construction, non-occultation handling, and invalid-state failure handling.
- Implemented Step 9 fixed-schema CSV export beneath `outputs/`.
- Added optional Keplerian-element export using a separate Mars-centered `J2000` state so rotating-frame `IAU_MARS` geometry is not reused for osculating elements.
- Added Step 9 tests for fixed-schema CSV writing and optional Keplerian-element export.
- Implemented Step 10 deterministic batch execution from YAML case definitions in `config/` with one CSV export per successful case.
- Added Step 10 tests for stable case ordering, per-case output creation, and isolated failed-case handling.
- Implemented Step 11 integrated output validation before successful export, including finiteness, angle-range, and tangent-geometry consistency checks.
- Added Step 11 tests for valid output bundles plus expected failures for non-finite values, invalid solar angles, and inconsistent non-occultation geometry.
