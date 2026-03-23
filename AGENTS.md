# AGENTS.md — Strict Mode Execution Contract for Codex

## 1. Purpose

This file defines the required behavior of any coding agent working in this repository.

In strict mode, the agent must prefer correctness, explicitness, and controlled scope over speed or creativity.

`PLAN.md` defines what to build.
This file defines how the agent must behave while building it.

Both are authoritative.

---

## 2. Primary Rules

### 2.1 Always follow the plan
- always consult `PLAN.md`
- implement work in the order specified there
- do not skip ahead unless the user explicitly instructs it
- if there is ambiguity, stop and explain rather than guessing

### 2.2 Respect strict environment assumptions
- never download kernels
- never access network resources for SPICE data
- always use `KERNELS_PATH` as the root for all kernel discovery
- always assume the canonical IDL executable is:
  `/Applications/NV5/idl/bin/idl`
- never assume `idl` is on `PATH`
- never replace IDL as the primary implementation language for the base pipeline

### 2.3 Fail early and visibly
- do not hide missing prerequisites
- do not silently continue after a required failure
- print clear, actionable diagnostic messages
- make it obvious which stage failed and why

---

## 3. Scope Control

### 3.1 Allowed scope for the base pipeline
The agent may implement:

- environment validation
- kernel discovery and loading
- time conversion and time-grid support
- state-vector retrieval
- coordinate conversion
- solar geometry
- tangent-point geometry
- CSV export
- batch orchestration
- validation helpers

### 3.2 Disallowed scope before base completion
The agent must not add any of the following unless the user explicitly requests it after the base pipeline works:

- kernel downloaders
- remote queries
- GUI tools
- plotting dashboards
- radiative-transfer solvers
- retrieval algorithms
- parallel frameworks
- Python replacements for the IDL base pipeline
- Fortran replacements for the IDL base pipeline
- architectural rewrites unrelated to the current step

---

## 4. Repository Behavior Rules

### 4.1 File placement
- source modules belong under `src/`
- configuration belongs under `config/`
- outputs belong under `outputs/`
- planning and control files stay at repository root

### 4.2 File changes
- modify only files relevant to the current task
- do not rename files casually
- do not create duplicate modules that fragment logic
- prefer extending the planned structure over inventing alternate structures

### 4.3 Dependency discipline
- do not add new external dependencies unless they are clearly necessary and explicitly justified
- for the base pipeline, prefer core IDL/ICY and simple repository-contained logic

### 4.4 Changelog discipline
- maintain `CHANGELOG.md` at the repository root for meaningful repository changes
- a local Git `post-commit` hook is responsible for appending timestamped commit entries to `CHANGELOG.md`
- when editing `CHANGELOG.md` directly, record only completed, factual changes
- when editing `CHANGELOG.md` directly, keep entries concise, chronological, and traceable to the implemented work
- update the `Completed Steps` section in `README.md` whenever a PLAN step is completed

---

## 5. Scientific and SPICE Conventions

The agent must preserve the following conventions unless the user explicitly changes them.

### 5.1 Core SPICE usage
Use these routines where appropriate:
- `cspice_furnsh`
- `cspice_str2et`
- `cspice_spkezr`
- `cspice_reclat`

### 5.2 Geometry conventions
- target spacecraft: `TGO`
- observer: `MARS`
- frame: `IAU_MARS`

### 5.3 Altitude convention
- use a documented Mars mean radius in the base implementation
- define the value in one place
- do not silently mix spherical and ellipsoidal assumptions

### 5.4 Occultation convention
- the initial tangent point is the minimum-radius point on the spacecraft-to-Sun line
- the code must not claim more sophisticated physics than it actually implements
- non-occultation cases must be flagged explicitly

---

## 6. Coding Style Requirements

### 6.1 General style
- prefer readable code over clever code
- keep functions small and purpose-specific
- isolate environment checks from science calculations
- isolate export logic from geometry logic
- write comments where conventions or assumptions matter

### 6.2 Error handling
- every module that can fail should emit a clear message
- required failures should stop the relevant workflow
- do not return fabricated default values to mask failures

### 6.3 Constants and conventions
- define important constants once
- avoid scattered magic numbers
- document units in code comments where needed

---

## 7. Validation Rules

Strict mode requires validation at each meaningful stage.

### 7.1 Before proceeding to a later stage
The agent should confirm that the earlier stage is logically complete.

Examples:
- do not implement batch mode before a single case works
- do not implement tangent geometry before state vectors are working
- do not trust manual lat/lon conversion without comparison to SPICE

### 7.2 Mandatory checks
The agent must include or preserve checks for:
- defined and readable `KERNELS_PATH`
- required kernel existence
- successful SPICE kernel load
- finite state vectors
- latitude and longitude plausibility
- finite tangent-point geometry
- no NaNs in required outputs

### 7.3 Validation against SPICE
When a SPICE cross-check routine exists and is appropriate, use it.
At minimum, compare manual coordinate conversion against `cspice_reclat`.

---

## 8. Output Rules

### 8.1 CSV requirements
CSV output must use a fixed schema with a documented column order.

At minimum, required columns should include:
- case id
- UTC and/or ET
- spacecraft latitude
- spacecraft longitude
- spacecraft altitude
- solar geometry term(s)
- tangent-point latitude
- tangent-point longitude
- tangent-point altitude

Optional columns may include Keplerian elements when that export mode is explicitly requested.
These elements must not be treated as mandatory for every run.

### 8.2 Failure handling in outputs
- do not quietly emit partial rows that look valid when a computation failed
- either mark the failure explicitly or prevent the bad row from being presented as successful output
- in batch mode, isolate per-case failures clearly

---

## 9. Batch Execution Behavior

When implementing batch mode:

- read cases deterministically from repository configuration
- execute cases in a stable order
- produce one output artifact per case unless a different scheme is explicitly chosen
- preserve enough per-case diagnostics to identify failures quickly
- do not allow one failed case to silently invalidate all others

---

## 10. Decision Policy When Uncertain

If the agent is uncertain, it must not bluff.

Use this policy:

1. stop
2. state the uncertainty clearly
3. explain the consequence of choosing incorrectly
4. propose one or more grounded options
5. wait for user direction when the uncertainty is material

Material uncertainties include:
- kernel-selection ambiguity
- frame ambiguity
- radius-definition ambiguity
- occultation-sign convention ambiguity
- output-schema choices that affect downstream use

---

## 11. Incremental Development Workflow

The agent should implement the repository in the following progression:

1. environment validation
2. kernel discovery and load
3. one single-epoch state-vector retrieval
4. reusable time handling
5. spacecraft geometry conversion
6. solar geometry
7. tangent-point geometry
8. CSV export
9. batch mode
10. integrated validation and cleanup

At each stage:
- keep the code runnable
- avoid broad refactors unless required
- preserve prior working behavior

---

## 12. What the Agent Must Never Do

The agent must never:

- download kernels
- fetch remote files to compensate for missing local prerequisites
- assume alternate executable paths for IDL
- silently switch the repository to another language
- skip validation to make progress appear faster
- claim a result is physically validated when it is only algebraically computed
- conceal uncertainty behind confident wording
- broaden scope beyond the current stage without approval

---

## 13. Preferred Communication Style in Code Changes

When preparing code or patch sets, the agent should favor:

- explicit names
- small modules
- comments near non-obvious geometry
- conservative assumptions
- deterministic behavior

Avoid:
- sprawling monolithic scripts when a small module is appropriate
- unnecessary cleverness
- hidden conventions

---

## 14. Completion Standard

The agent should consider the base strict-mode implementation complete only when:

- the first-priority PLAN goals are implemented
- the code runs end-to-end using the documented IDL path
- local kernels are resolved only through `KERNELS_PATH`
- validation checks are present and pass for the tested cases
- outputs are structured and traceable
- no prohibited shortcuts were used

---

## 15. Final Strict Reminder

The correct behavior in this repository is disciplined engineering.

When forced to choose, prefer:
- smaller scope over speculative scope
- explicit failure over silent failure
- verified output over impressive-looking output
- maintainable structure over flashy architecture
