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
- `KERNELS_PATH` must be defined and must point to a readable local kernel root directory.
- `python3` must be available and able to import the `yaml` module.
- The local ICY DLM directory, descriptor, and shared library must be available in:
  `/Users/mwolff/lib/Darwin_arm64`
- `nsp_run_pipeline.pro` expects to be launched from the repository root so it can add `src/` to `!PATH` automatically.
- `nsp_run_batch.pro` expects to be launched from the repository root so it can add `src/` to `!PATH` automatically.
- `nsp_run_tests.pro` expects to be launched from the repository root so it can add both `src/` and `tests/` to `!PATH` automatically.
- Repository exports are written beneath the root `outputs/` directory.
- Batch case definitions are read from repository YAML configuration beneath `config/`.
- Meta-kernel resolution is performed only beneath `KERNELS_PATH`.
- The default meta-kernel name is `em16_ops.tm`.
- Step 5 state retrieval uses frame `IAU_MARS`, observer `MARS`, target `TGO`, and aberration correction `NONE`.
- Step 6 geometry uses a documented Mars mean radius of `3389.5 km` for spherical altitude.
- Step 7 solar geometry uses frame `IAU_MARS`, observer `MARS`, target `SUN`, aberration correction `NONE`, and reports a spacecraft-local solar zenith angle defined between the outward radial vector and the spacecraft-to-Sun direction.
- Step 8 occultation geometry treats the initial tangent point as the minimum-radius point on the spacecraft-to-Sun line and flags non-occultation cases explicitly instead of returning misleading tangent geometry.
- Optional Keplerian-element export is available in Step 9 only when explicitly requested, and those elements are derived from a separate Mars-centered `J2000` state rather than the rotating `IAU_MARS` state.
- Step 11 validates the integrated output bundle before CSV writing, including required finiteness, solar-angle range checks, and tangent-geometry consistency.
- The repository does not download kernels and does not fall back to guessed paths.

Install the Python YAML module with:

```sh
python3 -m pip install --user --break-system-packages PyYAML
```

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

To resolve a different meta-kernel name, pass it explicitly:

```idl
NSP_RUN_PIPELINE, META_KERNEL_NAME='some_other.tm'
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

Step 10 batch execution reads deterministic case definitions from `config/tgo_cases.yaml` by default and writes one CSV per successful case beneath `outputs/`:

```idl
CD, '/Users/mwolff/processing_local/chatgpt/naif_orbit_v2/naif_satellite_position'
.COMPILE 'nsp_run_batch.pro'
NSP_RUN_BATCH
```

The batch configuration format is:

```yaml
cases:
  - case_id: some_case_id
    utc: '2025-01-01T00:00:00'
    output_filename: some_case_id.csv
    include_keplerian_elements: false
```

`case_id` and `utc` are required. `output_filename` is optional and defaults to `case_id + '.csv'`. `include_keplerian_elements` is optional and defaults to `false`. Batch cases are executed in the YAML list order, and one failed case is reported explicitly without preventing later cases from running.

## Tests

Step-specific test routines now live under the repository root `tests/` directory.

A focused test run is available through the test entrypoint:

```idl
CD, '/Users/mwolff/processing_local/chatgpt/naif_orbit_v2/naif_satellite_position'
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
- execution stops immediately with a clear message if `KERNELS_PATH` is missing or invalid
- execution stops immediately with a clear message if `python3` cannot import `yaml`
- execution stops immediately with a clear message if the ICY DLM directory, `icy.dlm`, or `icy.so` is missing or unreadable
- execution stops immediately with a clear message if the requested meta-kernel is missing, unreadable, or ambiguous in the deterministic search locations beneath `KERNELS_PATH`
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
