# Requirements: Real-Time df/f Monitoring via ScanImage User Functions

Status: **Requirements discovery complete** (via `/sc:brainstorm`). Not yet designed or implemented.
Next step: `/sc:design` (architecture) or `/sc:workflow` (implementation plan) before any code is written under `dev/`.

## 1. Goal

Add a first real-time data processing tool to `Session_user_functions/`: compute and display df/f
on the fly during a ScanImage acquisition, using ScanImage's User Functions event hooks
(https://archive.scanimage.org/SI2023/Advanced%2BFeatures/User%2BFunctions.html).

This is the first of a planned set of real-time tools; keep the buffer/event scaffolding reusable
for later additions (e.g. per-ROI extraction, motion correction) rather than single-purpose.

## 2. Event → Action → Output (confirmed)

| Event | Action | Output |
|---|---|---|
| `acqModeStart` | Create/empty a circular FIFO buffer of raw frames on the GPU (single functional channel); open/reset the dedicated live-plot window | Buffer ready to accept frames; GUI window visible and empty |
| `frameAcquired` | Pull latest frame via `src.hSI.hDisplay.lastFrame{chanIdx}`, push into GPU circular buffer, compute whole-FOV mean intensity trace over the buffer, run `dff_calc.m` (unmodified) on that trace | Live df/f plot updates in the dedicated window |

Both callbacks follow the ScanImage user-function signature `function name(src, evt, varargin)`,
with `src.hSI` giving access to the ScanImage model.

## 3. Key Decisions (from discovery)

- **Buffer content**: raw frames (image stack), stored on GPU (`gpuArray`), not pre-extracted traces.
  Chosen to keep the buffer reusable for future per-ROI / motion-correction extensions, even though
  v1's own signal (whole-FOV mean) doesn't strictly need raw pixels.
- **ROI scope (v1)**: whole-FOV placeholder — no polygon ROI UI yet. df/f is computed on the
  frame-mean trace only. Per-ROI extraction (reusing the polygon-mask approach in
  `Session_analysis/app/Utils/extract_traces.m`) is explicitly deferred, not in scope for this task.
- **Channel scope**: single functional channel, matching the existing
  `app.PIPELINE.PARAMS.functional_ch` convention from `Session_analysis`.
- **df/f recompute strategy**: on every `frameAcquired`, call the existing `dff_calc.m`
  (`Session_analysis/app/Proc/dff_calc.m`) unmodified over the *entire current buffer contents*
  (not a true streaming/incremental algorithm). This reuses validated math but means per-frame cost
  scales with buffer length — see Non-Functional Requirements.
- **Buffer sizing**: fixed **time window** (e.g. last ~20 s), with frame count derived from the
  session's frame rate at `acqModeStart` (not a fixed frame count, and not a per-session GUI prompt).
- **GPU availability**: assumed confirmed present (CUDA-capable GPU + Parallel Computing Toolbox) —
  no fallback/preflight-check path required for v1.
- **GUI placement**: new dedicated standalone figure/App for live df/f display, decoupled from the
  offline `Session_analysis` app (no shared axes/state).
- **Frame access API**: `src.hSI.hDisplay.lastFrame{chanIdx}` — user-confirmed, but **not verified
  against the actual running ScanImage install/version in this repo** (SI2023 docs; repo's MDF files
  reference SI2021/SI2020 configs). Flagged as a risk below.

## 4. Functional Requirements

- FR1: On `acqModeStart`, allocate a GPU-resident circular buffer sized for the configured time
  window × current frame rate, for the configured functional channel only. Any prior buffer content
  is discarded (never reused across acquisition modes).
- FR2: On `acqModeStart`, open (or clear/reset if already open) the dedicated live df/f plot window.
- FR3: On `frameAcquired`, retrieve the newest frame for the functional channel and push it into the
  circular buffer, evicting the oldest frame once full (FIFO).
- FR4: On `frameAcquired`, compute the whole-FOV mean-intensity trace across all frames currently in
  the buffer, run `dff_calc.m` on that trace with the session's fps/tau parameters, and update the
  live plot with the newest df/f value(s).
- FR5: Parameters passed to `dff_calc.m` (fps, tau_0, tau_1, tau_2, invert) must be explicit and
  logged per CLAUDE.md reproducibility requirements — not silently hardcoded/defaulted without a
  record of what was used for a given session.

## 5. Non-Functional Requirements

- NFR1 (performance): `frameAcquired` must return well within one inter-frame interval to avoid
  blocking the acquisition pipeline (docs don't state SI's tolerance here — treat as a hard
  constraint to validate empirically). Because df/f is recomputed over the full buffer every frame,
  buffer length (time window) directly trades off against per-frame compute cost — needs empirical
  tuning once real frame rate/frame dimensions are known.
- NFR2 (data integrity): this tool only reads from ScanImage's live display buffer; it must never
  write to or mutate raw acquisition data or files (CLAUDE.md §2).
- NFR3 (reproducibility): each session's buffer window length, channel index, and dff_calc
  parameters must be logged (CLAUDE.md §3) — mechanism (console log vs file) TBD in design phase.
- NFR4 (isolation): new code goes under `Session_user_functions/dev/` first per CLAUDE.md §13
  sandboxing rules; promotion to `proc/`/`gui/`/`io/`/`utils/` only after synthetic validation +
  user approval.

## 6. Open Questions / Risks (unresolved — needed before/during design)

1. **Frame access API not verified**: `src.hSI.hDisplay.lastFrame{chanIdx}` was user-supplied, not
   confirmed against the live ScanImage install. First implementation step should verify this
   against the actual `hSI` object (e.g. `disp(hSI.hDisplay)`) before building buffer logic on top
   of it.
2. **Cleanup events**: only `acqModeStart`/`frameAcquired` were specified. Should `acqModeDone`,
   `acqAbort`, and/or `acqStart` also be hooked (e.g. to freeze/finalize the plot, release GPU
   memory, or handle a mid-acquisition abort cleanly)? Currently out of scope but likely needed for
   a robust tool.
3. **Frame rate source**: buffer sizing needs fps at `acqModeStart` — exact `hSI` property to read
   this (e.g. `hSI.hRoiManager.scanFrameRate`) is unconfirmed, same category of risk as #1.
4. **dff_calc parameter source**: should tau_0/tau_1/tau_2/invert be hardcoded defaults (matching
   `dff_calc.m`'s own defaults), read from a config file, or exposed in the new live GUI for
   per-session adjustment?
5. **Registration mechanism**: programmatic registration via `hSI.hUserFunctions` vs. configuring
   through the MDF/USR User Functions panel — not yet decided; affects how these functions get
   wired into a live ScanImage session.
6. **GPU buffer overflow/dtype**: pixel bit-depth and channel image dimensions aren't yet known —
   needed to size the GPU buffer and avoid unnecessary GPU memory churn per push.

## 7a. Investigation: does dff_calc.m need changes to run on GPU? (validated 2026-07-15)

Empirically tested (not just read) on this machine: MATLAB R2024b, NVIDIA RTX A2000
(ComputeCapability 8.6), Parallel Computing Toolbox licensed and available.

- **Result: no code changes needed.** `dff_calc.m` uses only `movmean`, `movmin`, `filter`,
  `isnan`, and elementwise arithmetic — all of which have `gpuArray` overloads. Calling
  `dff_calc(gpuArray(data), ...)` returns a `gpuArray` result that matches the CPU result to
  within ~1e-16 (float noise), for both the default path and `invert=true`.
- **Timing (600-sample buffer, i.e. ~20s @ 30fps, matching this doc's buffer-size decision)**:
  GPU ≈ 0.59 ms/call, CPU ≈ 0.11 ms/call. **CPU is faster** here — GPU kernel-dispatch overhead
  dominates at this small trace size. Both are far under the 33 ms/frame budget at 30 fps, so
  neither is a bottleneck for v1, but this means running `dff_calc` itself on GPU has **no
  performance benefit** for a single whole-FOV trace.
- **Decision (2026-07-15, user)**: despite CPU being marginally faster at this trace size, keep the
  whole-FOV trace and the `dff_calc` call on GPU (`gpuArray` in, `gpuArray` out) rather than
  `gather()`ing to CPU. Switching between GPU/CPU here is a one-line change either way, so this is
  chosen for a single consistent GPU-resident code path rather than for performance — the ~0.5ms
  difference is irrelevant against the 33ms/frame budget. This resolves the "does dff_calc need a
  GPU-specific rewrite" question raised before implementation: it does not — call it directly on
  the gpuArray trace as-is.
- Not yet tested: R2020b (the other MATLAB install on this machine, closer to this repo's
  SI2020/SI2021 MDF configs) — behavior on the GPU-support side is unlikely to differ materially,
  but hasn't been empirically confirmed the way R2024b was.

## 7. Acceptance Criteria (for eventual implementation)

- AC1: Starting a GRAB/LOOP acquisition triggers `acqModeStart` → buffer allocated on GPU, live
  plot window opens empty, no errors.
- AC2: Each acquired frame triggers `frameAcquired` → live plot updates with a new df/f point,
  visually within one frame period of acquisition (no visible lag accumulation over a multi-minute
  acquisition).
- AC3: df/f values computed live match `dff_calc.m` run offline on the same buffered frame-mean
  trace, within floating-point tolerance (synthetic validation per CLAUDE.md §8: inject a known
  df/f transient into synthetic frame data, confirm the live pipeline recovers it).
- AC4: Starting a second acquisition (new `acqModeStart`) fully discards the previous buffer/plot
  state — no stale data carries over.
- AC5: No raw acquisition files are read, written, or modified by this tool (read-only against
  ScanImage's live display buffer).
