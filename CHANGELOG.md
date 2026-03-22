# Changelog

## 2026-03-22
- Added strict Step 1 environment validation for `KERNELS_PATH` and `python3` YAML-module availability.
- Implemented deterministic meta-kernel resolution under `KERNELS_PATH` with default `em16_ops.tm`.
- Added a reusable cross-repo `changelog-maintainer` skill and enforced changelog maintenance in repository rules.
- Documented the direct arm64 IDL binary as the Codex sandbox debugging fallback when the canonical launcher fails its architecture probe.
- Fixed meta-kernel resolution to use deterministic candidate paths instead of the broken recursive wildcard search.
- Renamed the repository root directory from devel to naif_satellite_position and updated repository path references.
