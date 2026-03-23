# Changelog

## 2026-03-23
- 2026-03-23 12:33:32 CET commit b59e2a3: Use post-commit hook for changelog timestamps


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
