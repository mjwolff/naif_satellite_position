# CLAUDE.md — naif_satellite_position

SPICE-based ephemeris pipeline for the ExoMars Trace Gas Orbiter, using NASA ICY DLM (`cspice_*` calls).

## Environment prerequisites

- `KERNEL_PATH` env var must point to the directory containing SPICE meta-kernels. Never download kernels; all kernel discovery starts here.
- ICY DLM path resolved from `NSP_ICY_DLM_PATH` env var, or defaults to `/Users/mwolff/lib/Darwin_arm64`.
- IDL executable: `/Applications/NV5/idl/bin/idl`. Never assume `idl` is on `PATH`.

## Running the pipeline

All commands run from the `naif_satellite_position/` project root with a clean IDL
environment (`env -i`) to prevent an `IDL_STARTUP` file from injecting stale paths.

```bash
# Run all 11 test suites
env -i HOME=$HOME PATH=$PATH KERNEL_PATH=<path> \
  /Applications/NV5/idl/bin/idl \
  -e "!path = EXPAND_PATH('+src') + ':' + EXPAND_PATH('+tests') + ':' + !path" \
  -e "NSP_RUN_TESTS"

# Single-point pipeline validation (Steps 1-3: validate, resolve, load kernels)
env -i HOME=$HOME PATH=$PATH KERNEL_PATH=<path> \
  /Applications/NV5/idl/bin/idl \
  -e "!path = EXPAND_PATH('+src') + ':' + !path" \
  -e "NSP_RUN_PIPELINE"

# Batch CSV generation from YAML config
env -i HOME=$HOME PATH=$PATH KERNEL_PATH=<path> \
  /Applications/NV5/idl/bin/idl \
  -e "!path = EXPAND_PATH('+src') + ':' + !path" \
  -e "NSP_RUN_BATCH"
```

All NSP routines must be on `!path` before calling any entry point.

### Invocation notes

**Run from the project root.** `EXPAND_PATH('+src')` resolves relative to the shell's
working directory. If not in `naif_satellite_position/`, the path setup silently fails
and IDL may find stale copies of routines elsewhere on its path.

**IDL startup file interference.** An `IDL_STARTUP` file may add stale paths that shadow
`src/`. The `env -i HOME=$HOME PATH=$PATH` prefix above strips the startup file and gives
IDL a clean default path.

**Bash history expansion.** The `!` in `!path` is expanded by bash inside double-quoted
strings, silently breaking the path assignment. The `-e "..."` form above works when
invoked non-interactively (e.g. from a script or Claude Code). In an interactive shell,
either run `set +H` first to disable history expansion, or use a batch file:

```bash
cat > /tmp/run_nsp.pro << 'EOF'
!path = '/abs/path/to/src:/abs/path/to/tests:' + !path
NSP_RUN_TESTS
EOF
env -i HOME=$HOME PATH=$PATH KERNEL_PATH=<path> \
  /Applications/NV5/idl/bin/idl -e "@/tmp/run_nsp.pro"
```

## Pipeline structure (11 steps)

| Step | Module | Purpose |
|------|--------|---------|
| 1 | `nsp_validate_environment` | Check `KERNEL_PATH`, IDL YAML parser, ICY DLM |
| 2 | `nsp_resolve_kernels` | Locate meta-kernel beneath `KERNEL_PATH` |
| 3 | `nsp_load_kernels` | Initialize ICY, clear pool, furnsh meta-kernel |
| 4 | `nsp_build_time_grid` | Build uniformly spaced ET grid from UTC start/step/count |
| 5 | `nsp_get_tgo_state` | Retrieve TGO state via `cspice_spkezr` in `IAU_MARS` frame |
| 6 | `nsp_compute_geometry_from_state` | Convert position to planetocentric lat/lon/radius/altitude |
| 7 | `nsp_compute_solar_geometry` | S/C-to-Sun vector and spacecraft-local SZA |
| 8 | `nsp_compute_occultation_geometry` | Tangent point and occultation flag |
| 9 | `nsp_export_csv` | Write fixed-schema CSV (24 base + 8 optional Keplerian columns) |
| 10 | `nsp_run_batch` | Read YAML cases, execute each, write aggregate CSV |
| 11 | `nsp_validate_outputs` | Finiteness, angle ranges, tangent-geometry consistency |

## SPICE geometry conventions

These are fixed for this pipeline. Do not change without explicit instruction.

- **Target:** `TGO`
- **Observer:** `MARS`
- **Frame:** `IAU_MARS` (Mars-fixed body frame)
- **Aberration correction:** `NONE` (geometric positions, no light-time delay)
- **Mars mean radius:** 3389.5 km — defined once in `nsp_mars_mean_radius_km.pro`; never mix spherical and ellipsoidal assumptions
- **Longitude:** [-π, π] radians, east positive
- **Solar zenith angle:** spacecraft-local; angle between outward radial and S/C-to-Sun vectors
- **Tangent point:** minimum-radius point on the spacecraft-to-Sun line segment; cases where this falls outside the segment are flagged `occultation_valid = 0`

## EXECUTE() wrapper

All `cspice_*` calls are wrapped in `EXECUTE()` for late-load compatibility with the ICY DLM:

```idl
status = EXECUTE("cspice_spkezr, target, et, frame, abcorr, obs, state, ltime")
```

This is load-order safety, not optional style. Do not remove it.

## Coding conventions

- `compile_opt idl2` in every routine (strict array subscripting + additional IDL 2 safety checks)
- One `.pro` file per routine; filename matches routine name exactly
- File layout: `src/` for production modules, `tests/` for test suites, `config/` for YAML batch configs, `outputs/` for generated CSV/PNG
- Constants defined once (never scattered magic numbers); units documented in comments where non-obvious
- Every public routine has an IDL doc header: `NAME`, `PURPOSE`, `CATEGORY`, `CALLING SEQUENCE`, `INPUTS`, `OUTPUTS`, `NOTES`, `MODIFICATION HISTORY`

## Error handling

- Fail early and visibly: print a clear diagnostic before stopping, never silently continue
- Every error message identifies which Step failed: `"Step 3 kernel load failed: ..."`
- Do not return fabricated defaults to mask failures
- Mandatory checks before proceeding: `KERNEL_PATH` readable, meta-kernel exists, ICY load succeeded, state vectors finite, lat/lon plausible, tangent geometry finite, no NaNs in required outputs

## CSV output schema

Fixed 24-column base schema (column order is part of the public interface):

```
case_id, utc, et,
sc_x_km, sc_y_km, sc_z_km, sc_vx_km_s, sc_vy_km_s, sc_vz_km_s,
sc_longitude_rad, sc_latitude_rad, sc_radius_km, sc_altitude_km,
solar_zenith_angle_rad, subsolar_latitude_rad, subsolar_longitude_rad,
occultation_valid,
tangent_x_km, tangent_y_km, tangent_z_km,
tangent_longitude_rad, tangent_latitude_rad, tangent_radius_km, tangent_altitude_km
```

Optional 8 Keplerian columns (per-case flag in YAML):
```
kep_rp_km, kep_eccentricity, kep_inclination_rad,
kep_longitude_of_ascending_node_rad, kep_argument_of_periapsis_rad,
kep_mean_anomaly_rad, kep_epoch_et, kep_mu_km3_s2
```

Numeric format: `E24.16E3`. Non-finite values written as `'NaN'`.

## Batch YAML config format

Cases may be single UTC points or UTC ranges expanded with `dt_seconds`. One aggregate CSV per batch run. Failed cases are recorded with `batch_status` and `failure_message` columns; one failure does not abort subsequent cases.

## Design priorities

When correctness and other goals conflict, prefer in this order:
1. correctness
2. explicitness
3. reproducibility
4. validation
5. maintainability
6. performance

## Time convention

Use SPICE ET internally for all calculations. Preserve original UTC strings in outputs for human readability. Avoid ambiguous local-time assumptions.

## Changelog hook

A `prepare-commit-msg` hook auto-stages a timestamped entry into `CHANGELOG.md` with each commit. Include `[skip-changelog]` in the commit subject to suppress it.
