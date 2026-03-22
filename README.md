# Mars SPICE Pipeline

This repository is being built in the strict order defined by `PLAN.md`.

## Current implemented stage

Only **Step 1 - environment validation** and **Step 2 - kernel resolution** are implemented.

## Execution requirements

- IDL must be invoked with the canonical executable path:
  `/Applications/NV5/idl/bin/idl`
- In this Codex environment, the canonical launcher may fail before user code runs because its internal architecture probe is sandbox-restricted. For local debugging in that environment, the direct arm64 IDL binary is:
  `/Applications/NV5/idl92/bin/bin.darwin.arm64/idl`
- `KERNELS_PATH` must be defined and must point to a readable local kernel root directory.
- `python3` must be available and able to import the `yaml` module.
- Meta-kernel resolution is performed only beneath `KERNELS_PATH`.
- The default meta-kernel name is `em16_ops.tm`.
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

From the IDL prompt, change into the repository and compile the current files:

```idl
CD, '/Users/mwolff/processing_local/chatgpt/naif_orbit_v2/devel'
.COMPILE 'src/validate_environment.pro'
.COMPILE 'src/resolve_kernels.pro'
.COMPILE 'run_pipeline.pro'
RUN_PIPELINE
```

To resolve a different meta-kernel name, pass it explicitly:

```idl
RUN_PIPELINE, META_KERNEL_NAME='some_other.tm'
```

Expected behavior:

- execution stops immediately with a clear message if `KERNELS_PATH` is missing or invalid
- execution stops immediately with a clear message if `python3` cannot import `yaml`
- execution stops immediately with a clear message if the requested meta-kernel is missing, unreadable, or ambiguous in the deterministic search locations beneath `KERNELS_PATH`
- execution prints the validated kernel root and the resolved meta-kernel path when the current checks pass
