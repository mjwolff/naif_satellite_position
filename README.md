# Mars SPICE Pipeline

This repository is being built in the strict order defined by `PLAN.md`.

## Completed Steps

- Step 1: environment validation
- Step 2: kernel resolution
- Step 3: kernel loading
- Step 4: time handling
- Step 5: single-epoch state-vector retrieval

## Current implemented stage

Only **Step 1 - environment validation**, **Step 2 - kernel resolution**, **Step 3 - kernel loading**, **Step 4 - time handling**, and **Step 5 - single-epoch state-vector retrieval** are implemented.

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
- `nsp_run_tests.pro` expects to be launched from the repository root so it can add both `src/` and `tests/` to `!PATH` automatically.
- Meta-kernel resolution is performed only beneath `KERNELS_PATH`.
- The default meta-kernel name is `em16_ops.tm`.
- Step 5 state retrieval uses frame `IAU_MARS`, observer `MARS`, target `TGO`, and aberration correction `NONE`.
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

Expected behavior:

- execution stops immediately with a clear message if `src/` is not available from the current working directory
- execution stops immediately with a clear message if `tests/` is not available from the current working directory
- execution stops immediately with a clear message if `KERNELS_PATH` is missing or invalid
- execution stops immediately with a clear message if `python3` cannot import `yaml`
- execution stops immediately with a clear message if the ICY DLM directory, `icy.dlm`, or `icy.so` is missing or unreadable
- execution stops immediately with a clear message if the requested meta-kernel is missing, unreadable, or ambiguous in the deterministic search locations beneath `KERNELS_PATH`
- execution stops immediately with a clear message if `cspice_furnsh` cannot load the resolved meta-kernel
- execution stops immediately with a clear message if `cspice_str2et` cannot convert the requested UTC string
- execution stops immediately with a clear message if `cspice_spkezr` cannot retrieve the requested state vector
- execution prints the validated kernel root, the resolved meta-kernel path, and the loaded kernel count when the current checks pass
