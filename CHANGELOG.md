# Changelog

## 2026-03-22
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
