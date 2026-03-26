# Mars SPICE Pipeline

This repository is being built in the strict order defined by `PLAN.md`.

## Completed Steps

- Step 1: environment validation
- Step 2: kernel resolution
- Step 3: kernel loading
- Step 4: time handling
- Step 5: single-epoch state-vector retrieval
- Step 6: geometry conversion
- Step 7: solar geometry
- Step 8: occultation geometry
- Step 9: CSV export
- Step 10: batch execution
- Step 11: integrated validation pass

## Current implemented stage

Only **Step 1 - environment validation**, **Step 2 - kernel resolution**, **Step 3 - kernel loading**, **Step 4 - time handling**, **Step 5 - single-epoch state-vector retrieval**, **Step 6 - geometry conversion**, **Step 7 - solar geometry**, **Step 8 - occultation geometry**, **Step 9 - CSV export**, **Step 10 - batch execution**, and **Step 11 - integrated validation pass** are implemented.

## Execution requirements

- IDL must be invoked with the canonical executable path:
  `/Applications/NV5/idl/bin/idl`
- In this Codex environment, the canonical launcher may fail before user code runs because its internal architecture probe is sandbox-restricted. For local debugging in that environment, the direct arm64 IDL binary is:
  `/Applications/NV5/idl92/bin/bin.darwin.arm64/idl`
- `KERNEL_PATH` must be defined and must point to a readable local kernel root directory.
- The native IDL `YAML_PARSE` routine must be available from the installed IDL distribution.
- The ICY DLM path is resolved in this order: IDL keyword `ICY_DLM_PATH`, environment variable `ICY_DLM_PATH`, then the default `/Users/mwolff/lib/Darwin_arm64`.
- The resolved ICY DLM directory, descriptor, and shared library must all exist and be readable.
- `nsp_run_pipeline.pro` expects to be launched from the repository root so it can add `src/` to `!PATH` automatically.
- `nsp_run_batch.pro` expects to be launched from the repository root so it can add `src/` to `!PATH` automatically.
- `nsp_run_tests.pro` expects to be launched from the repository root so it can add both `src/` and `tests/` to `!PATH` automatically.
- Root-level `nsp_setup_path.pro` provides the shared `!PATH` setup used by the repository entrypoints.
- Repository exports are written beneath the root `outputs/` directory.
- Batch case definitions are read from repository YAML configuration beneath `config/`.
- Meta-kernel resolution is performed only beneath `KERNEL_PATH`.
- The default meta-kernel name is `em16_ops.tm`.
- Step 5 state retrieval uses frame `IAU_MARS`, observer `MARS`, target `TGO`, and aberration correction `NONE`.
- Step 6 geometry uses a documented Mars mean radius of `3389.5 km` for spherical altitude.
- Step 7 solar geometry uses frame `IAU_MARS`, observer `MARS`, target `SUN`, aberration correction `NONE`, and reports a spacecraft-local solar zenith angle defined between the outward radial vector and the spacecraft-to-Sun direction.
- Step 8 occultation geometry treats the initial tangent point as the minimum-radius point on the spacecraft-to-Sun line, flags non-occultation cases explicitly, and uses a working occultation-event definition based on tangent altitude crossing the atmospheric range from `0 km` to `altitude_max` (default `150 km`).
- Optional Keplerian-element export is available in Step 9 only when explicitly requested, and those elements are derived from a separate Mars-centered `J2000` state rather than the rotating `IAU_MARS` state.
- Step 11 validates the integrated output bundle before CSV writing, including required finiteness, solar-angle range checks, and tangent-geometry consistency.
- The repository does not download kernels and does not fall back to guessed paths.

## Run the current validation stage

Start IDL with the required executable:

```sh
/Applications/NV5/idl/bin/idl
```

If the canonical launcher fails in the Codex sandbox with `Unable to recognize system architecture.`, use the direct binary for debugging there:

```sh
/Applications/NV5/idl92/bin/bin.darwin.arm64/idl
```

From the IDL prompt, change into the repository and compile only the entrypoint:

```idl
CD, '/Users/mwolff/processing_local/chatgpt/naif_orbit_v2/naif_satellite_position'
.COMPILE 'nsp_run_pipeline.pro'
NSP_RUN_PIPELINE
```

To set up the repository autoload path explicitly before compiling other routines:

```idl
CD, '/Users/mwolff/processing_local/chatgpt/naif_orbit_v2/naif_satellite_position'
.COMPILE 'nsp_setup_path.pro'
NSP_SETUP_PATH
```

To override the ICY DLM path explicitly, pass the `ICY_DLM_PATH` keyword:

```idl
NSP_RUN_PIPELINE, ICY_DLM_PATH='/Users/mwolff/lib/Darwin_arm64'
```

To resolve a different meta-kernel name, pass it explicitly:

```idl
NSP_RUN_PIPELINE, META_KERNEL_NAME='some_other.tm'
```

Or set the same name in the environment before starting IDL:

```sh
export ICY_DLM_PATH=/Users/mwolff/lib/Darwin_arm64
```

## Time handling usage

After `NSP_RUN_PIPELINE` has loaded kernels and added `src/` to `!PATH`, Step 4 helpers can be used directly:

```idl
et_value = NSP_UTC_TO_ET('2025-01-01T00:00:00')
print, et_value

grid = NSP_BUILD_TIME_GRID('2025-01-01T00:00:00', 60D, 3L)
print, grid
```

Or use the reporting procedure:

```idl
NSP_TIME_GRID, START_UTC='2025-01-01T00:00:00', STEP_SECONDS=60D, POINT_COUNT=3L, ET_VALUES=grid
```

## State-vector usage

After kernels are loaded, Step 5 state retrieval can be used directly with one ET value:

```idl
et_value = NSP_UTC_TO_ET('2025-01-01T00:00:00')
NSP_STATE_VECTORS, ET=et_value, STATE_VECTOR=state_vector, LIGHT_TIME=light_time
```

## Geometry usage

After Step 5 is available, Step 6 geometry conversion can be used with the same ET value:

```idl
et_value = NSP_UTC_TO_ET('2025-01-01T00:00:00')
NSP_GEOMETRY, ET=et_value, STATE_VECTOR=state_vector, LONGITUDE=longitude, LATITUDE=latitude, RADIUS=radius, ALTITUDE=altitude
```

Longitude and latitude are returned in radians. Radius and altitude are returned in kilometers.

## Solar geometry usage

After Step 6 is available, Step 7 solar geometry can be used with the same ET value:

```idl
et_value = NSP_UTC_TO_ET('2025-01-01T00:00:00')
NSP_SOLAR_GEOMETRY, ET=et_value, STATE_VECTOR=state_vector, SUN_STATE_VECTOR=sun_state_vector, SPACECRAFT_TO_SUN_VECTOR=spacecraft_to_sun_vector, SOLAR_ZENITH_ANGLE=solar_zenith_angle
```

`SOLAR_ZENITH_ANGLE` is returned in radians. The current definition is spacecraft-local: the angle between the outward radial vector and the spacecraft-to-Sun direction.

## Occultation usage

After Step 7 is available, Step 8 occultation geometry can be used with the same ET value:

```idl
et_value = NSP_UTC_TO_ET('2025-01-01T00:00:00')
NSP_OCCULTATION, ET=et_value, TANGENT_POINT_VECTOR=tangent_point_vector, TANGENT_LONGITUDE=tangent_longitude, TANGENT_LATITUDE=tangent_latitude, TANGENT_RADIUS=tangent_radius, TANGENT_ALTITUDE=tangent_altitude, OCCULTATION_VALID=occultation_valid, CLOSEST_APPROACH_DISTANCE=closest_approach_distance
```

If `OCCULTATION_VALID` is `0`, the code explicitly flags a non-occultation case and leaves the tangent-point geometry values non-finite instead of presenting them as valid outputs.

For this project, an occultation event is defined operationally from a time-ordered tangent-altitude profile. A profile is considered part of an atmospheric occultation only while the tangent altitude is within `0 km <= tangent_altitude <= altitude_max`, with `altitude_max` defaulting to `150 km`. An ingress occultation is one in which tangent altitude decreases with time, so the event begins when the profile crosses into that range from above, usually at `150 km`, and ends when it reaches `0 km`. An egress occultation is one in which tangent altitude increases with time, so the event begins when the profile crosses into that range from below, usually at `0 km`, and ends when it reaches `150 km`. In practice, event extraction should require `OCCULTATION_VALID = 1` together with finite tangent altitude before applying this ingress or egress classification.

## Export usage

After kernels are loaded, Step 9 export can write one CSV file per run beneath `outputs/`:

```idl
NSP_EXPORT_CSV, UTC_STRING='2025-01-01T00:00:00', CASE_ID='single_case', OUTPUT_FILENAME='single_case.csv', OUTPUT_PATH=output_path
print, output_path
```

The fixed base CSV schema is:

```text
case_id,utc,et,sc_x_km,sc_y_km,sc_z_km,sc_vx_km_s,sc_vy_km_s,sc_vz_km_s,sc_longitude_rad,sc_latitude_rad,sc_radius_km,sc_altitude_km,solar_zenith_angle_rad,occultation_valid,tangent_x_km,tangent_y_km,tangent_z_km,tangent_longitude_rad,tangent_latitude_rad,tangent_radius_km,tangent_altitude_km
```

Optional Keplerian columns can be appended explicitly:

```idl
NSP_EXPORT_CSV, UTC_STRING='2025-01-01T00:00:00', CASE_ID='single_case_kep', OUTPUT_FILENAME='single_case_kep.csv', OUTPUT_PATH=output_path, /INCLUDE_KEPLERIAN_ELEMENTS
```

The optional Keplerian columns are appended in this order:

```text
kep_rp_km,kep_eccentricity,kep_inclination_rad,kep_longitude_of_ascending_node_rad,kep_argument_of_periapsis_rad,kep_mean_anomaly_rad,kep_epoch_et,kep_mu_km3_s2
```

## Batch usage

Step 10 batch execution reads deterministic case definitions from `config/tgo_cases.yaml` by default and writes one aggregate CSV per batch run beneath `outputs/`:

```idl
CD, '/Users/mwolff/processing_local/chatgpt/naif_satellite_position'
.COMPILE 'nsp_run_batch.pro'
NSP_RUN_BATCH
```

Batch execution accepts the same optional `ICY_DLM_PATH` keyword and environment-variable override used by `NSP_RUN_PIPELINE`.

The batch configuration format is:

```yaml
cases:
  - case_id: some_case_id
    utc: '2025-01-01T00:00:00'
    output_filename: some_case_id.csv
    include_keplerian_elements: false
  - case_id: some_case_series
    utc_start: '2025-01-01T00:00:00'
    utc_end: '2025-01-01T01:00:00'
    dt_seconds: 600
    include_keplerian_elements: true
```

Each batch entry must define either:

- `case_id` plus a single `utc`
- `case_id` plus `utc_start`, `utc_end`, and positive integer `dt_seconds`

For single-UTC entries, `output_filename` remains optional for schema compatibility, but batch execution now writes one aggregate CSV named from the batch config file. For UTC-range entries, `output_filename` must be omitted; the reader expands the range into one case per timestamp with generated case identifiers of the form `case_id_YYYY_MM_DD_HHMMSS`. UTC-range spans must be exact multiples of `dt_seconds`, and batch cases are executed in YAML list order after expansion. The aggregate CSV preserves one row per expanded case, adds `batch_status` and `failure_message` columns, and keeps failed cases isolated without preventing later cases from running.

Example batch configuration: to compute TGO positions for 3 hours starting at `2025-01-01T00:00:00` with `dt_seconds: 5`, use [`config/example_tgo_occultation_3h.yaml`](/Users/mwolff/processing_local/chatgpt/naif_satellite_position/config/example_tgo_occultation_3h.yaml):

```yaml
cases:
  - case_id: tgo_occultation_3h
    utc_start: '2025-01-01T00:00:00'
    utc_end: '2025-01-01T03:00:00'
    dt_seconds: 5
```

Run it with:

```sh
#!/bin/zsh
set -euo pipefail

export KERNEL_PATH=/Volumes/Wolff_misc1/nomad_naif/tgo_kernels/

/Applications/NV5/idl92/bin/bin.darwin.arm64/idl <<'IDL'
CD, '/Users/mwolff/processing_local/chatgpt/naif_satellite_position'
.COMPILE 'nsp_run_batch.pro'
NSP_RUN_BATCH, CONFIG_PATH='config/example_tgo_occultation_3h.yaml'
EXIT
IDL
```

This expands to 2161 batch cases and writes one aggregate CSV at `outputs/example_tgo_occultation_3h.csv`. Each row includes the `occultation_valid` column, which is the explicit occultation flag for that spacecraft position, along with `batch_status` and `failure_message` columns for per-case diagnostics.

Example batch configuration: to compute one year of daily TGO states starting at `2025-01-01T00:00:00` and also export Keplerian elements, use [`config/example_tgo_keplerian_1y.yaml`](/Users/mwolff/processing_local/chatgpt/naif_satellite_position/config/example_tgo_keplerian_1y.yaml):

```yaml
cases:
  - case_id: tgo_keplerian_1y
    utc_start: '2025-01-01T00:00:00'
    utc_end: '2026-01-01T00:00:00'
    dt_seconds: 86400
    include_keplerian_elements: true
```

Run the batch and then plot the relative change of the non-dynamic Keplerian elements (`kep_rp_km`, `kep_eccentricity`, `kep_inclination_rad`, `kep_longitude_of_ascending_node_rad`, and `kep_argument_of_periapsis_rad`) with:

```idl
CD, '/Users/mwolff/processing_local/chatgpt/naif_satellite_position'
.COMPILE 'nsp_run_batch.pro'
NSP_RUN_BATCH, CONFIG_PATH='config/example_tgo_keplerian_1y.yaml'

.COMPILE 'nsp_setup_path.pro'
NSP_SETUP_PATH
.COMPILE 'src/nsp_plot_keplerian_relative_change.pro'
NSP_PLOT_KEPLERIAN_RELATIVE_CHANGE, 'outputs/example_tgo_keplerian_1y.csv', TITLE='TGO 2025 Daily Keplerian Drift', OUTPUT_PNG_PATH='outputs/example_tgo_keplerian_1y_relative_change.png', /USE_X
```

This example expands to 366 daily epochs from `2025-01-01T00:00:00` through `2026-01-01T00:00:00` inclusive. The plotting helper reads the aggregate CSV with `nsp_read_output_csv`, filters successful rows, unwraps the angular elements before differencing, and writes five separate larger plots with black axes on a white background and one colored data line per element. With `/USE_X`, each figure is rendered in an X window and captured with `TVRD(/TRUE)` before being written. With the example base path above, the PNG outputs are written as `outputs/example_tgo_keplerian_1y_relative_change_kep_rp_km.png` and the corresponding suffixed files for the other four elements.

To extract occultation events from that aggregate batch CSV, call:

```idl
NSP_EXTRACT_OCCULTATION_EVENTS, 'outputs/example_tgo_occultation_3h.csv', SURVEY=survey, EVENT_COUNT=event_count
PRINT, survey.n_ingress
PRINT, survey.n_egress
PRINT, survey.events.type
PRINT, survey.events.i_start
PRINT, survey.events.i_end
```

The returned `survey` structure contains per-step arrays mapped from the batch CSV: `time`, `tang_alt`, `tang_lat`, `tang_lon`, `n_int`, `sat_lat`, `sat_lon`, `sat_alt`, `ss_lat`, and `ss_lon`. It also reports `n_ingress`, `n_egress`, and `events`, where `events` is a structure array sorted by `t_start` or scalar `-1` when no events are found. Each event struct contains `type`, `ingress`, `i_start`, `i_end`, `t_start_interp`, `t_end_interp`, `t_start`, `t_end`, `duration_interp`, `tang_alt_min`, `lat_min`, `lon_min`, `tang_alt_max`, `lat_max`, and `lon_max`. Times are taken from the batch CSV `et` column in seconds, while latitude and longitude values are reported in degrees. The extractor groups contiguous successful rows where `OCCULTATION_VALID = 1` and `0 km <= tangent_altitude_km <= altitude_max_km`, with `altitude_max_km` defaulting to `150 km`. `survey.n_int` is the current 0/1 atmospheric-intersection mapping from that same window, `survey.ss_lat` is the first finite sub-solar latitude sample, and `type='ING'` means tangent altitude decreases from `altitude_max_km` toward `0 km` while `type='EGR'` means it increases from `0 km` toward `altitude_max_km`.


## Tests

Step-specific test routines now live under the repository root `tests/` directory.

A focused test run is available through the test entrypoint:

```idl
CD, '/Users/mwolff/processing_local/chatgpt/naif_satellite_position'
.COMPILE 'nsp_run_tests.pro'
NSP_RUN_TESTS
```

The current test set checks:
- Step 4 UTC-to-ET conversion against direct `cspice_str2et`
- Step 4 regular 3-point ET grid spacing
- Step 4 empty-UTC failure handling
- Step 4 invalid-point-count failure handling
- Step 5 single-epoch TGO state retrieval against direct `cspice_spkezr`
- Step 5 invalid-ET failure handling
- Step 6 spacecraft geometry conversion against direct `cspice_reclat`
- Step 6 altitude computation from the documented Mars mean radius
- Step 6 invalid-state failure handling
- Step 7 Sun state retrieval against direct `cspice_spkezr`
- Step 7 spacecraft-local solar zenith angle against the direct dot-product definition
- Step 7 invalid-spacecraft-state failure handling
- Step 8 tangent-point construction on the spacecraft-to-Sun line
- Step 8 explicit non-occultation flagging
- Step 8 invalid-spacecraft-state failure handling
- Step 9 fixed-schema CSV export under `outputs/`
- Step 9 optional Keplerian-element export from a separate Mars-centered `J2000` state
- Step 10 deterministic batch execution from YAML case definitions
- Step 10 isolated per-case failures with continued execution of later cases
- Step 11 integrated output finiteness and plausibility validation

Expected behavior:

- execution stops immediately with a clear message if `src/` is not available from the current working directory
- execution stops immediately with a clear message if `tests/` is not available from the current working directory
- execution stops immediately with a clear message if `outputs/` is not available from the current working directory
- execution stops immediately with a clear message if `KERNEL_PATH` is missing or invalid
- execution stops immediately with a clear message if the native IDL `YAML_PARSE` routine is unavailable
- execution stops immediately with a clear message if the ICY DLM directory, `icy.dlm`, or `icy.so` is missing or unreadable
- execution stops immediately with a clear message if the requested meta-kernel is missing, unreadable, or ambiguous in the deterministic search locations beneath `KERNEL_PATH`
- execution stops immediately with a clear message if `cspice_furnsh` cannot load the resolved meta-kernel
- execution stops immediately with a clear message if `cspice_str2et` cannot convert the requested UTC string
- execution stops immediately with a clear message if `cspice_spkezr` cannot retrieve the requested state vector
- execution stops immediately with a clear message if geometry conversion or `cspice_reclat` validation fails
- execution stops immediately with a clear message if Sun state retrieval or solar geometry validation fails
- execution stops immediately with a clear message if occultation geometry construction fails
- execution stops immediately with a clear message if integrated output validation fails
- execution stops immediately with a clear message if CSV export or optional Keplerian-element export fails
- batch execution continues past a failed case, reports that case explicitly, and still writes outputs for later successful cases
- execution prints the validated kernel root, the resolved meta-kernel path, and the loaded kernel count when the current checks pass
