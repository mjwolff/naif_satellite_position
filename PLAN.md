# PLAN.md — Strict Mode Mars SPICE Pipeline (TGO)

## 1. Objective

Build a reproducible, modular, IDL/ICY-based Mars/SPICE pipeline for Trace Gas Orbiter (TGO) geometry and occultation analysis.

The initial pipeline shall:

- load required local NAIF/SPICE kernels
- compute spacecraft state vectors relative to Mars
- derive planetocentric latitude, longitude, and altitude
- compute solar geometry products
- compute solar-occultation tangent-point geometry
- export structured tabular outputs
- support controlled batch execution through case definitions

This plan is the authoritative build sequence for the repository.

---

## 2. Strict Environment Assumptions (MANDATORY)

These assumptions are hard requirements and are not optional.

### 2.1 Kernel location
All required NAIF kernels are assumed to already exist on the local system.

The kernel root directory is provided by the environment variable:

`KERNELS_PATH`

Rules:

- never download kernels
- never clone kernel repositories
- never fetch files from NAIF or any other network source
- never create a replacement local kernel cache inside the repository
- always resolve kernel paths from `KERNELS_PATH`

### 2.2 IDL location
The IDL executable is fixed and must be treated as authoritative:

`/Applications/NV5/idl/bin/idl`

Rules:

- always invoke IDL using this absolute path
- never assume `idl` is available on `PATH`
- never substitute another executable
- never switch the primary execution model away from IDL for the base pipeline

### 2.3 Path handling
Rules:

- use absolute paths whenever practical
- fail early if a required path is missing
- do not silently fall back to guessed paths
- do not hard-code user-specific kernel subdirectories unless they are explicitly discovered under `KERNELS_PATH`

### 2.4 Repository behavior
Rules:

- keep repository-contained outputs in `outputs/`
- keep configuration in `config/`
- keep implementation modules in `src/`
- do not store kernels in the repository

---

## 3. Definition of Done

The initial pipeline is complete only when all of the following are satisfied.

### 3.1 Single-case execution
A single-case run can be launched from IDL and completes without manual intervention.

### 3.2 Required outputs
Each successful run produces a structured output file containing, at minimum:

- case identifier
- UTC timestamp and/or ET
- spacecraft Cartesian state relative to Mars
- spacecraft planetocentric latitude
- spacecraft longitude
- spacecraft altitude above the adopted mean-radius surface
- solar zenith angle or equivalent solar geometry term
- tangent-point Cartesian position
- tangent-point latitude
- tangent-point longitude
- tangent-point altitude

### 3.3 Batch execution
Multiple cases can be run from a case-definition file, producing one output artifact per case.

### 3.4 Validation
The pipeline includes at least the following validation checks:

- kernel-path validation before SPICE load
- successful kernel loading
- latitude/longitude cross-check against SPICE routines such as `cspice_reclat`
- no NaN or obviously invalid numeric outputs
- basic tangent-point sanity checks

### 3.5 Reproducibility
The pipeline can be rerun with the same inputs and produce equivalent outputs, modulo expected floating-point formatting differences.

---

## 4. Explicit Non-Goals for the Initial Build

The following are outside the scope of the first implementation and must not be added until the base pipeline is complete and validated:

- online kernel acquisition
- remote data access
- GUI applications
- plotting dashboards
- radiative transfer solvers
- retrieval algorithms
- atmospheric forward models
- migration of the base implementation to Python, Fortran, or any other language
- speculative optimization or parallelization before correctness is demonstrated

These may appear later only as explicitly approved extensions.

---

## 5. Canonical Repository Layout

The repository should converge toward the following layout:

```text
mars_spice_pipeline/
├── PLAN.md
├── AGENTS.md
├── config/
│   └── tgo_cases.yaml
├── src/
│   ├── nsp_load_kernels.pro
│   ├── nsp_resolve_kernels.pro
│   ├── nsp_time_grid.pro
│   ├── nsp_state_vectors.pro
│   ├── nsp_geometry.pro
│   ├── nsp_solar_geometry.pro
│   ├── nsp_occultation.pro
│   ├── nsp_export_csv.pro
│   └── nsp_validate_outputs.pro
├── nsp_run_pipeline.pro
├── nsp_run_batch.pro
└── outputs/
```

Notes:

- additional helper modules are allowed if they improve clarity
- names may be adjusted slightly only if there is a strong repository-wide reason
- outputs must remain separated from source code

---

## 6. Ordered Build Sequence

The build must proceed in the following order unless the user explicitly overrides it.

### Step 1 — environment validation
Implement code that:

- reads `KERNELS_PATH`
- verifies it is non-empty
- verifies the directory exists
- verifies the fixed IDL path assumption is documented in execution instructions
- fails immediately with a clear error if prerequisites are not satisfied

Deliverable:
- minimal environment validation logic

### Step 2 — kernel resolution
Implement code that:

- locates required kernel files or a usable meta-kernel beneath `KERNELS_PATH`
- resolves absolute paths
- distinguishes between required and optional kernels
- emits clear diagnostics when required files are missing

Deliverable:
- kernel-resolution module and a deterministic strategy for kernel discovery

### Step 3 — kernel loading
Implement code that:

- loads the resolved meta-kernel or generated meta-kernel via `cspice_furnsh`
- verifies load success insofar as possible
- keeps the loading logic isolated from science calculations

Deliverable:
- `nsp_load_kernels.pro`

### Step 4 — time handling
Implement code that:

- converts UTC strings to ET using SPICE
- supports a single timestamp first
- then supports a regular time grid

Deliverable:
- minimal UTC→ET helper and then reusable time-grid module

### Step 5 — single-epoch state-vector retrieval
Implement code that:

- retrieves the TGO state relative to Mars
- uses frame `IAU_MARS`
- uses a clearly documented aberration correction setting
- prints or records the result for one epoch

Deliverable:
- `nsp_state_vectors.pro` with single-epoch test

### Step 6 — geometry conversion
Implement code that:

- converts spacecraft position to latitude/longitude/radius
- computes altitude above a clearly documented Mars mean radius
- performs validation against `cspice_reclat`

Deliverable:
- `nsp_geometry.pro`

### Step 7 — solar geometry
Implement code that:

- computes Sun-relative geometry needed for SZA or similar quantities
- keeps conventions explicit
- validates sign and angle ranges where practical

Deliverable:
- `nsp_solar_geometry.pro`

### Step 8 — occultation geometry
Implement code that:

- defines the line of sight from spacecraft toward the Sun
- computes the minimum-radius point along that line
- returns tangent-point position and derived coordinates
- flags geometrically invalid or non-occultation cases cleanly

Deliverable:
- `nsp_occultation.pro`

### Step 9 — export
Implement code that:

- writes CSV output with a fixed schema
- writes one file per run or case
- includes enough metadata columns for traceability
- optionally calculates and exports Keplerian elements when explicitly requested for a run
- does not require Keplerian-element calculation for every export

Deliverable:
- `nsp_export_csv.pro`

### Step 10 — batch execution
Implement code that:

- reads case definitions from configuration
- loops over cases deterministically
- isolates failures cleanly
- writes separate outputs per case

Deliverable:
- `nsp_`

### Step 11 — integrated validation pass
Implement code that:

- runs validation after computation
- checks for NaNs
- checks angle/range plausibility
- checks tangent-altitude plausibility
- reports failures clearly

Deliverable:
- `nsp_validate_outputs.pro`

---

## 7. Science and Geometry Conventions

These conventions must be kept explicit in code comments and output documentation.

### 7.1 Frame and observer conventions
- target spacecraft: `TGO`
- observer body: `MARS`
- frame: `IAU_MARS`

### 7.2 Radius convention
The initial implementation shall use a documented Mars mean radius for altitude calculations.

Rules:

- define the numerical value in one place
- document the unit
- do not mix spherical and ellipsoidal definitions silently

### 7.3 Occultation convention
For the initial implementation:

- define the tangent point as the minimum-radius point on the spacecraft-to-Sun line
- clearly indicate whether the geometry corresponds to a true occultation or just a line-of-sight minimum
- do not overclaim physical validity beyond the implemented mathematics

### 7.4 Time convention
Rules:

- use SPICE ET internally when practical
- preserve original UTC definitions for human readability in outputs
- avoid ambiguous local-time assumptions

---

## 8. Required Validation Checks

The following checks are mandatory for strict mode.

### 8.1 Environment checks
- `KERNELS_PATH` exists and is readable
- required kernel files exist
- output directory exists or is created intentionally

### 8.2 SPICE checks
- kernel load does not fail silently
- single-epoch state-vector retrieval succeeds before multi-epoch execution is attempted

### 8.3 Geometry checks
- latitude is within valid bounds
- longitude convention is documented and consistent
- altitude is numerically finite
- manual coordinate conversion is compared against SPICE-based conversion

### 8.4 Occultation checks
- tangent-point solution is finite
- tangent altitude is plausible relative to line-of-sight geometry
- non-occultation cases are flagged, not hidden

### 8.5 Output checks
- no NaNs in required columns
- column order is fixed and documented
- one malformed case does not silently corrupt all outputs

---

## 9. Failure Policy

Strict mode requires explicit failure behavior.

Rules:

- fail early on missing environment requirements
- fail loudly on missing required kernels
- never silently skip required computation stages
- never fabricate output values to fill missing data
- for batch mode, isolate a failed case and report it clearly
- do not mark a run successful unless required validation passes

---

## 10. Logging and Diagnostics

The implementation should provide concise but useful diagnostics.

At minimum, log:

- the resolved `KERNELS_PATH`
- whether a meta-kernel was found or generated
- the primary kernels selected
- the current case identifier
- the start UTC and ET range
- whether each major stage completed successfully
- validation failures with enough detail to debug the issue

Do not overwhelm the user with excessive debug output unless explicitly requested.

---

## 11. Execution Instructions

### 11.1 Single run
The canonical invocation shall be documented as:

```bash
/Applications/NV5/idl/bin/idl nsp_run_pipeline.pro
```

### 11.2 Batch run
The canonical batch invocation shall be documented as:

```bash
/Applications/NV5/idl/bin/idl nsp_
```

No alternative primary execution path should be introduced for the base pipeline.

---

## 12. Immediate First Task

The first implementation task is deliberately narrow.

Implement:

1. environment validation for `KERNELS_PATH`
2. kernel discovery or meta-kernel discovery beneath `KERNELS_PATH`
3. kernel loading
4. one single-epoch TGO state-vector retrieval
5. direct printing or recording of that result

Do not begin batch mode, export refinements, or occultation calculations before this first task works.

---

## 13. Approved Next Tasks After the First Task

Only after the first task works, proceed in this order:

1. reusable time-grid support
2. spacecraft latitude/longitude/altitude
3. solar geometry
4. tangent-point geometry
5. CSV export
6. batch execution
7. integrated validation

---

## 14. Extension Roadmap After Base Validation

These are approved later-phase directions, not initial tasks.

### Phase 2 — geometry refinement
- ellipsoidal Mars support
- sub-spacecraft point
- sub-solar point
- local solar time

### Phase 3 — occultation science
- tangent-path sampling
- slant path length
- Chapman-function support
- atmospheric profile hooks

### Phase 4 — radiative transfer
- line-of-sight optical depth
- dust and ice extinction terms
- radiative-transfer coupling

### Phase 5 — cross-language validation
- Python/SpiceyPy comparison tools
- Fortran validation modules

### Phase 6 — data-product maturation
- NetCDF output
- provenance capture
- PDS-oriented metadata structures

---

## 15. Priority Rules

If there is tension between different goals, use this order of priority:

1. correctness
2. explicitness
3. reproducibility
4. validation
5. maintainability
6. performance

---

## 16. Final Strict-Mode Reminder

This repository is for disciplined pipeline construction.

Do not improvise around missing prerequisites.
Do not fetch external data.
Do not silently change conventions.
Do not skip validation.
Do not expand scope before the base pipeline works.
