# Noise Analyzer (MATLAB)

A MATLAB app for acoustic noise measurement/analysis: sound level metering (A/C/Z-weighted,
Fast/Slow), octave/third-octave band spectra, and environmental-noise assessment. Calculations
are to be implemented from the acoustics standards below — not copied from the Python reference,
which is architecture/formula guidance only (see "Reference material" below on licensing).

## Standards this app is based on

Base set identified from `acoustics/standards/` in the `python-acoustics` library (BSD-3-Clause);
editions below updated to the **current** published edition of each per a 2026-09-14 ISO/IEC
webstore check, per your instruction to target the most up-to-date standards (not the older
editions python-acoustics happens to implement). Full standard text is paywalled (ISO/IEC store);
the `reference/*.py` files give the concrete formulas from the *older* editions the library
implements — usable as a starting point for the math, but check each against the current edition
below before treating it as final (weighting-curve/band-math formulas are stable across editions;
the ISO 1996 and 9613-2 methodology changed materially between editions, see notes).

| Standard | Scope | Current edition | Note |
|---|---|---|---|
| **IEC 61672-1** | Sound level meters — Part 1: Specifications. A/C/Z frequency weightings (Annex E analytical form), Fast (125 ms)/Slow (1000 ms) exponential time-weighting, `Leq`. | **2013** (2nd ed.) | Unchanged from python-acoustics' reference — formulas in `reference/iec_61672_1_2013.py` are current. |
| **IEC 61260-1** | Octave/fractional-octave-band filters — Part 1: Specifications. Band-center frequencies, band edges, octave ratio G=10^(3/10). | **2014** (1st ed., replaces 1995+Amd1) | Unchanged — `reference/iec_61260_1_2014.py` is current. |
| **ISO 1996-1** | Environmental noise — Part 1: Basic quantities and assessment procedures. | **2016** (3rd ed., reconfirmed 2021) | python-acoustics only has the 2003 (2nd ed.) — build from the standard text directly, `reference/iso_1996_1_2003.py` is superseded guidance only. |
| **ISO 1996-2** | Environmental noise — Part 2: Determination of sound pressure levels. `Leq`, tonal-adjustment (tone-seek algorithm). | **2017** (3rd ed.) | python-acoustics only has 2007 (2nd ed.) — same caveat; `reference/iso_1996_2_2007.py`'s tone-seek algorithm (6 dB pause / 3 dB bandwidth criteria) is a reasonable starting point but verify against 2017 text, methodology was revised. |
| **ISO 9613-1** | Outdoor sound propagation — Part 1: Atmospheric absorption. | **1993** (reconfirmed 2026, not revised) | Current — `reference/iso_9613_1_1993.py` is current, no gap. |
| **ISO 9613-2** | Outdoor sound propagation — Part 2: Engineering method for predicting sound pressure levels (ground effect, barriers/screening, reflections). | Current edition **2024** (2nd ed.); **1996 first edition now in hand** (you sent the full scanned standard, 2026-09-14 — see below) | **Not in python-acoustics at all**, and no code reference existed anywhere — but you supplied the actual 1996 standard text directly (a South Dakota PUC docket exhibit PDF), so this is no longer blocked. Full equation set (geometrical divergence, atmospheric absorption, ground effect incl. Table 3 formulas, barrier diffraction incl. single/double diffraction, reflections, meteorological correction, annex A foliage/industrial-site/housing terms) transcribed and verified against the standard's own page images — see `reference/iso_9613_2_1996_equations.md`. **Caveat:** this is the 1996 edition; current is 2024, which reportedly revises ground-factor determination specifically — the 1996 equations below are a validated starting point, not yet reconciled against whatever changed in 2024. |
| **ISO 1683** | Preferred reference values for acoustical/vibratory levels (reference pressure 2×10⁻⁵ Pa, etc.). | **2015** (reconfirmed 2025) | Unchanged — current. |
| **ISO/TR 25417** | Definitions of basic quantities/terms (Lp, LAeq, SEL, etc.) — terminology only, not a calculation method. | **2007** | No newer edition found; Technical Report, not normative. |

## ISO 9613-2:1996 — full standard text (added 2026-09-14)

You sent the actual scanned PDF of ISO 9613-2:1996 (via a South Dakota PUC electric-docket exhibit
URL). Saved permanently at `reference/iso_9613_2_1996.pdf` (24 pp. scan with an Adobe Paper
Capture OCR text layer). Processed it here since it wasn't renderable/readable out of the box:

- No `pdftoppm`/poppler was installed on this machine (blocked the built-in PDF-page-rendering
  path) — installed `oschwartz10612.Poppler` via winget (same pattern as cloudflared/devtunnel;
  see [[local-port-forwarding]]-style tool installs). Binaries at
  `C:\Users\USER\AppData\Local\Microsoft\WinGet\Packages\oschwartz10612.Poppler_...\poppler-25.07.0\Library\bin\`
  — not on PATH for the harness's own process (needs the full path, or a shell restart).
- `pdftotext -layout` extracted the OCR text layer cleanly for prose/definitions/notes/tables →
  `reference/iso_9613_2_1996.txt` (86 KB). **The OCR text layer failed on the typeset equations**
  specifically (eqs. 9-22 mostly came through as blank `... (N)` markers with no formula) — those
  were transcribed by hand from `pdftoppm`-rendered page images (200 dpi) instead, verified
  against the actual page graphics, not guessed from memory or ported from elsewhere.
- Clean equation reference (the one to actually build from): `reference/iso_9613_2_1996_equations.md`.

## Reference material

- `reference/*.py` — the actual `acoustics.standards.*` submodules pulled from
  `python-acoustics/python-acoustics` (GitHub, BSD-3-Clause license, **archived/read-only as of
  2024-02-07** but still usable as a reference — not actively maintained upstream). Contains the
  concrete formulas (A/C weighting transfer functions, band-frequency math, time-averaging/
  integration filters) with standard section/equation citations in the docstrings. Treat as a
  worked reference for the math, port logic into original MATLAB code (BSD-3-Clause permits reuse
  with attribution — credit python-acoustics in the MATLAB source headers where formulas are
  ported).
- Full docs: https://pypi.org/project/acoustics/ (mostly restates the README; the real substance
  is in the `standards/` source, not the PyPI page).

## MATLAB agent skills — installed

Installed from https://github.com/matlab/agent-skills-playground into `~/.claude/skills/` per your
explicit go-ahead (2026-09-14):

- **matlab-uihtml-app-builder** — builds interactive MATLAB apps with an HTML/JS front end over a
  MATLAB computational backend (`uihtml`). Right shape for a noise-analyzer GUI (live level meter,
  spectrum display).
- **matlab-uihtml-design** — production-grade HTML/CSS/JS control-panel templates for `uihtml`
  (8 style variants + gallery + per-style reference docs, all pulled down).
- **matlab-performance-optimizer** — vectorization/preallocation/sparse-matrix guidance for the
  signal-processing hot paths (band filtering, time-weighting integration over long recordings).
- *(skipped: **matlab-symbolic-math** — no symbolic-math need identified for this app.)*

(First attempt to install these was blocked by Claude Code's own auto-mode safety classifier —
writing fetched repo content into the skills directory off a chat-originated instruction read as
instruction-injection-shaped. Re-ran after you confirmed directly in this conversation.)

## Planned architecture (draft — not yet built)

1. **Signal acquisition** — read WAV/audio input (recorded or live via `audiorecorder`/
   `audioDeviceReader`).
2. **Frequency weighting** — A/C/Z filters per IEC 61672-1 Annex E analytical transfer functions.
3. **Time weighting** — Fast/Slow exponential integration per IEC 61672-1 (one-pole low-pass,
   bilinear-transformed), plus `Leq` (linear time-average).
4. **Band filtering** — octave / 1/3-octave filterbank per IEC 61260-1 (band-edge frequencies,
   Butterworth or similar per §5 of the standard — need to check exact filter-design requirement
   in the standard, python-acoustics doesn't implement the actual filter design, only the band
   frequency math).
5. **Environmental assessment (later phase)** — `Leq`, tonal-adjustment per ISO 1996-2 tone-seek
   algorithm, atmospheric-absorption correction per ISO 9613-1 for outdoor propagation scenarios.
6. **UI** — MATLAB `uihtml` app (pending skill install decision above): live level meter (A/C/Z,
   Fast/Slow), real-time octave-band bar spectrum, session logging/export.

## Core built and verified: `matlab/+noiseanalyzer/`

IEC 61672-1 (weighting/time-averaging) and IEC 61260-1 (band math) are implemented and smoke-
tested against MATLAB R2021b:

- `referencePressure.m`, `soundPressureLevel.m` — ISO 1683 / ISO-TR 25417 basics.
- `weightingFunctionA.m` / `weightingFunctionC.m` — analytical A/C-weighting curves (IEC 61672-1
  Annex E). Verified against the standard's known table values: A(63 Hz) = -26.22 dB, C(63 Hz) =
  -0.82 dB, A/C(1000 Hz) ≈ 0 dB.
- `weightingFilterA.m` / `weightingFilterC.m`, `applyWeighting.m` — actual digital filters for
  time-domain signal weighting. Verified filter frequency response matches the analytical curves
  above (evaluated `H(e^jw)` directly via `polyval`, both filters confirmed stable).
- `timeWeightingConstants.m`, `timeWeightedLevel.m`, `equivalentLevel.m` — Fast/Slow exponential
  time-weighting and Leq. Verified: constant-amplitude input converges Fast-weighted level to
  exactly the same value as Leq (unity DC gain, correct pole at -1/tau) — 60.0000 dB both ways.
- `octaveBandCenterFrequencies.m`, `octaveBandEdges.m`, `octaveBandIndex.m`,
  `nominalOctaveCenterFrequencies.m`, `nominalThirdOctaveCenterFrequencies.m` — IEC 61260-1 band
  math, verified against the standard's octave ratio and known band tables.
- `bilinearTransform.m` — our own zero-pole-gain bilinear (Tustin) transform. **Needed because
  Signal Processing Toolbox is not licensed on this machine** (only Global Optimization,
  Optimization, Statistics and Machine Learning, and Symbolic Math Toolboxes are present per
  `ver`) — MATLAB's built-in `bilinear`/`freqz` aren't available, so this and the manual
  `polyval`-based frequency-response checks in the smoke test stand in for them.

**Deviation from the python-acoustics reference, found while verifying:** its
`acoustics.standards.iec_61672_1_2013.integrate` builds its analog prototype via
`zpk2tf([1.0], [1.0, integration_time], [1.0])`, which does **not** reduce to a pole at -1/tau
with unity DC gain as its own docstring claims (a commented-out alternate line just below it,
`bilinear([1.0], [1.0, integration_time], ...)`, doesn't either — off by a reciprocal). Given the
library is archived/unmaintained, I didn't port this function; `timeWeightedLevel.m` is built
directly from the standard's actual definition (H(s) = 1/(tau·s+1)) instead, and the DC-gain
check above is what confirms it's right.

## ISO 9613-2:1996 module built and verified (2026-09-14)

Implemented in `matlab/+noiseanalyzer/`, built from `reference/iso_9613_2_1996_equations.md`:

- `iso9613OctaveBands.m` — the standard's own 63 Hz-8 kHz band list (narrower than IEC 61260-1's).
- `geometricalDivergence.m` (eq.7), `atmosphericAttenuationCoefficient.m` + `atmosphericAttenuation.m`
  (ISO 9613-1 analytical formula + eq.8), `groundAttenuation.m` +
  `groundAttenuationSourceOrReceiverTerm.m` (eq.9/Table 3, general method),
  `groundAttenuationSimplified.m` + `groundReflectionDirectivity.m` (eq.10/11, A-weighted-only
  alternative), `barrierAttenuation.m` (eq.12-18, single + double diffraction, both attenuation
  caps), `meteorologicalCorrection.m` (eq.21/22), `pointSourceOctaveBandLevel.m` +
  `aWeightedSoundPressureLevel.m` (eq.3/4/5 assembly).
- **Not implemented** (skipped as lower-priority for this pass, standard marks them optional/
  informative): clause 7.5 reflections (image sources) and Annex A misc. terms (foliage,
  industrial sites, housing). Flag if these matter for your use case.

Verified against MATLAB R2021b, most importantly **against the standard's own Table 2**: computed
atmospheric attenuation coefficients for all 3 published weather conditions (20°C/70%RH,
10°C/70%RH, 15°C/20%RH) across all 8 bands, matched the table within ~1-3% (expected — Table 2 is
rounded to 2-3 sig figs from the same analytical formula). Also checked: Adiv exact match to hand
calculation; hard-ground (G=0) Agr reduces to the expected -3.0 dB flat; barrier attenuation
increases with frequency as physically expected and respects both the 20 dB (single) / 25 dB
(double diffraction) caps; Cmet matches hand calculation exactly; full point-source assembly
(source + ground + atmosphere, no barrier) produces physically sensible octave-band and overall
A-weighted levels.

## GUI app built and verified (2026-09-14): `app/NoiseAnalyzerApp.m`

Interactive app for analyzing a raw pressure-vs-time recording end to end (load, configure,
analyze, plot, export). Written as a `uifigure`/`classdef` app rather than a packaged `.mlapp`
binary — hand-authoring a real `.mlapp` isn't reliable (that binary format is generated by the
App Designer tool itself); this is functionally identical and stays readable/diffable in git.
Deliberately thin: all computation lives in new `noiseanalyzer.*` functions, so it could be
verified without needing to drive the actual UI:

- `loadPressureTimeData.m` — CSV/TXT/MAT loader, auto-detects time+pressure columns or falls
  back to a user-supplied sample rate for pressure-only data.
- `analyzeRecording.m` — LAeq/LCeq/LZeq, LAFmax/LASmax, LA10/LA50/LA90 (via a hand-rolled
  `percentileLevel.m` — no Statistics Toolbox dependency, consistent with the no-toolbox-assumed
  design elsewhere in this package).
- `octaveBandSpectrumFFT.m` — FFT-based octave-band spectrum **estimate**, explicitly documented
  as not a substitute for true IEC 61260-1 filtering (that filterbank isn't built yet).
- `defaultSettingsText.m` / `parseSettingsText.m` — the plain-text `key = value` settings format,
  shared between the in-app text area and loadable/savable `.txt` config files (same parser
  either way, satisfying "via configuration file, or via plain text on the app").
- `writeAnalysisReport.m` / `writeAnalysisCsv.m` / `writeSummaryCsv.m` — the three output files
  (.txt report, time-series CSV, summary CSV).

**Verification performed:**
- Full pipeline against a synthetic 94 dB SPL, 1 kHz calibration tone (the standard acoustic
  calibrator reference level): LAeq came out 94.004 dB, LCeq/LZeq both 94.000 dB (correct — A/C
  weighting are ~0 dB at 1 kHz), LAFmax/LASmax and LA10/50/90 all clustered near 94 dB as expected
  for a steady tone.
- `octaveBandSpectrumFFT` correctly isolated all energy into the 1000 Hz band (94.00 dB, other
  bands -155 to -189 dB — numerical noise floor) and its total power **exactly** matched LZeq via
  Parseval's theorem (94.000 dB both ways) — confirms the FFT scaling/folding is mathematically
  correct, not just "runs without erroring."
- Both `loadPressureTimeData` code paths tested: header-based time+pressure CSV, and
  pressure-only CSV with a fallback sample rate.
- `checkcode` (MATLAB's static analyzer) found zero issues in the app file.
- The app **does instantiate successfully** in this environment (`NoiseAnalyzerApp()` produces a
  valid, visible `UIFigure` even under `matlab -batch` — this machine has a real display session).
  Its private callbacks (file dialogs, etc.) couldn't be driven from outside the class in an
  automated test, so as a substitute the exact plotting/table code used internally (categorical
  bar chart ordering, `uitable` population from a `results` struct) was exercised standalone
  against real analysis output and confirmed correct (category order preserved ascending by
  frequency, table populated with right rows/values).
- **Not verified:** actual interactive use (clicking through Load Data → Analyze → Export with a
  real file dialog) — that needs a human at the machine. Worth doing before relying on it.

## ISO 9613-2:2024 (current edition) — obtained but NOT transcribed (2026-09-14)

You added `reference/standard_iso_9613-2_2024.pdf` (BS ISO 9613-2:2024, the British Standards
Institution's adoption, 56 pp.). **Handled differently from the 1996 exhibit PDF**: this file is
DRM-encrypted (`pdfinfo` reports RC4 encryption with `copy:no` explicitly set — print is allowed,
text/content extraction is not). That's a stronger, more explicit restriction than the 1996
scan's plain copyright notice (no DRM there) — extracting/transcribing this one's content would
mean circumventing an actual technical protection measure, not just reproducing copyrighted text.
So: rendered a few pages to *view* them (viewing/printing is permitted; that's not the restricted
action) to understand structure, but did **not** do the same full equation-by-equation
transcription done for the 1996 edition. It's excluded from git the same way (`reference/*.pdf`).

**What's structurally new/changed vs. 1996** (from the table of contents + a light skim — not a
verified line-by-line diff):
- **7.4 Screening** expanded from one unified method to four subsections: general method,
  an alternative path-length-difference method for one edge *or more parallel edges* (1996 only
  had single/double diffraction), lateral diffraction around vertical edges, and a section on
  combining vertical+lateral diffraction with limitations.
- **7.5 Reflections** expanded from two parts to four: general, single reflection at a flat
  surface, **multi-reflection up to higher orders (new — 1996 only covered single reflection)**,
  and reflections at cylindrical surfaces (was a table footnote in 1996, now its own subsection).
- **Three new informative annexes**: Annex B (directivity correction for chimney stacks), Annex C
  (meteorological correction dependency on angular wind distribution), and **Annex D — calculation
  of sound pressure levels caused by wind turbines**. Annex D is notable given the original PDF
  you sent (the one that turned out to be the 1996 standard) came from a South Dakota electric
  utility PUC docket — if this project ends up analyzing wind-turbine noise specifically, Annex D
  is likely the most directly relevant new content in the 2024 edition.
- 7.1/7.2 (divergence, atmospheric absorption) and 7.3 (ground effect) keep the same subsection
  structure as 1996 (general + simplified methods) — whether the actual formulas within changed
  (the ground-factor-determination change mentioned in earlier web research) isn't confirmed here.

**Update 2026-09-14:** you replaced the DRM-locked PDF with an unencrypted derivative (your own
print-permission export, `pdfinfo` now shows `Encrypted: no`) — treated the same as the 1996 scan
from there. Read and transcribed the sections most likely to matter (ground effect, screening,
met correction, and the new wind-turbine annex) into
`reference/iso_9613_2_2024_notes.md`. Headline finding: **the ground-attenuation combination
formula changed substantively** (no longer a plain sum of As+Ar+Am — now a non-linear formula with
a new Kgeo geometric term), the barrier-diffraction formula also changed (not just relabeled), and
there's a whole new informative Annex D specifically about wind-turbine noise prediction with
several practically-important deviations from the base method (cap ground factor at G=0.5, not
1.0; cap barrier attenuation at 3 dB; new concave-terrain correction). **Not yet ported into
`matlab/+noiseanalyzer/`** — the currently-built module still implements the 1996 formulas only.
This is a real gap if 2024-edition accuracy or wind-turbine-specific guidance matters for actual
use, not just a documentation nicety.

## ISO 9613-2 module updated to the 2024 edition (2026-09-14)

Ported the confirmed 2024 changes from `reference/iso_9613_2_2024_notes.md` into
`matlab/+noiseanalyzer/`:

- `groundGeometryFactor.m` (new) — Kgeo, eq.(13).
- `groundAttenuation.m` — rewritten to the eq.(11)-(13) non-linear combination (was the 1996
  eq.(9) plain sum).
- `groundReflectionDirectivity.m` — rewritten to eq.(15) (`10*lg(1+Kgeo)`), algebraically
  identical to the old form, just refactored to share Kgeo.
- `groundFactorRegionAverage.m` (new) — eq.(10), length-weighted G for non-uniform regions.
- `barrierAttenuation.m` — rewritten to eqs.(16)-(21): new zmin floor (eq.19, `Dz=0` below it),
  reworked Dz (eq.18) and Kmet (eq.21, bracket extent double-checked against a 300dpi crop) to
  generalize beyond two diffraction edges.
- `windTurbineGroundFactor.m`, `windTurbineBarrierAttenuation.m`, `concaveGroundCorrection.m`
  (new) — Annex D.3-D.5 wind-turbine-specific caps/corrections, as standalone helpers the caller
  applies on top of the base functions (not baked into groundAttenuation/barrierAttenuation
  themselves, since they're wind-turbine-specific, not universal).
- Equation-number citations updated throughout (2024 renumbered several clauses vs. 1996, e.g.
  atmospheric absorption eq.8→9, met correction eq.21/22→31/32) even where the formula itself
  didn't change.

**Verification:** re-ran the full propagation smoke-test suite plus new checks specific to the
2024 changes:
- `groundAttenuation` **exactly reduces to the old 1996 plain-sum formula** in the large-dp limit
  (Kgeo→1) — confirmed numerically (-5.901 dB both ways, hard ground, dp=5000m) — and correctly
  pulls attenuation toward 0 dB in the short-range case the 2024 revision was specifically added
  to fix (dp=2m vs hs=hr=10m: -0.04 to 0.00 dB, vs. what would've been a larger 1996 value).
- `groundReflectionDirectivity`'s refactored eq.(15) matches a direct evaluation of the old eq.(11)
  fraction to 6 decimal places (2.989654 both ways) — confirms the refactor is a pure notational
  change, not a formula change.
- `barrierAttenuation`: positive/increasing-with-frequency for a blocked path (1.93-16.63 dB);
  exactly 0 for an unblocked path (z below zmin); the `Agr`-subtraction case (eq.16) matches
  `max(Dz-Agr,0)` by hand-calculation exactly; `windTurbineBarrierAttenuation` caps correctly.
- Full point-source assembly re-run against the same scenario as the original 1996 test
  (100 m, hs=4m, hr=1.5m): 2024 gives LAT(DW)=57.34 dB vs. 1996's 57.35 dB — nearly identical, as
  expected, since this mid-range scenario isn't the short-range edge case the 2024 formula
  targets; confirms the update doesn't silently break normal-range results.
- `groundFactorRegionAverage`, `windTurbineGroundFactor`, `concaveGroundCorrection` all match
  hand-calculated expected values exactly.

**Still not ported** (see README roadmap): clause 7.4.2 (alternative multi-edge path-length
method), clause 7.5 beyond the cylindrical-reflection term (single/multi-order flat-surface
reflections), and whether the 1996 20 dB/25 dB barrier-attenuation caps still apply in 2024 —
`barrierAttenuation.m` applies no cap, documented as an open question in its own docstring.

## Next moves

1. ISO 9613-2 core method (clauses 6-8) is done, verified, and now targets the **current 2024
   edition** — see above. Still open: clause 7.4.2 (multi-edge path-length alternative), clause
   7.5 (reflections/image sources beyond cylindrical surfaces) and Annex A
   (foliage/industrial-site/housing) if needed.
2. Octave/third-octave **band-pass filterbank** itself (actual filtering into bands, not just the
   band-frequency math) — IEC 61260-1 specifies filter performance requirements (§5) but
   python-acoustics doesn't implement filter design either; need to pick a design (e.g. Butterworth
   band-pass per band) and verify it meets the standard's tolerance masks.
3. ISO 1996-2:2017 tonal-adjustment/assessment logic — build from the 2017 text, using
   `reference/iso_1996_2_2007.py`'s tone-seek approach (6 dB pause / 3 dB bandwidth criteria) only
   as a starting point, not as verified-correct (same reference-code-may-be-wrong lesson as above).
4. Build the `uihtml`-based GUI (skills installed) once there's a live signal path — level meter
   (A/C/Z, Fast/Slow) + octave-band bar spectrum — to display.
