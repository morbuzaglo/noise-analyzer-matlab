# Noise Analyzer

A MATLAB toolbox for acoustic noise measurement and outdoor-propagation analysis, built directly
from the underlying international standards rather than from any single reference implementation
— with every formula cross-checked against the standard's own published example numbers.

**Status:** core signal-processing and outdoor-propagation math implemented and verified. GUI and
octave-band filterbank not yet built. See [Roadmap](#roadmap).

## What it does

- **Sound level metering** — A/C/Z frequency weighting (as both analytical curves and actual
  digital filters), Fast/Slow exponential time-weighting, and equivalent-continuous level (Leq),
  per **IEC 61672-1:2013**.
- **Octave-band math** — exact and nominal octave / third-octave band-center frequencies, band
  edges, and band-index lookup, per **IEC 61260-1:2014**.
- **Outdoor sound propagation** — geometrical divergence, atmospheric absorption, ground effect
  (both the general per-band method and the simplified A-weighted alternative), barrier/screening
  diffraction (single and multi-edge), and meteorological correction, per **ISO 9613-2:2024**
  (current edition) — plus its informative Annex D deviations specifically for wind-turbine
  sources (ground-factor cap, barrier-attenuation cap, concave-terrain correction).
- **Source power estimation & attenuation fitting** — from multi-microphone measurements at
  several distances (including several mics sharing a radius), back-calculate the sound source's
  power level, predict the full ISO 9613-2 level-vs-distance curve (geometric spreading +
  atmospheric absorption + ground effect combined in one call), and fit unknown parameters —
  source power level and/or ground hardness — by nonlinear least-squares against the real
  measured attenuation, with a synthetic-data validation path since no calibrated multi-mic
  parameter is assumed known in advance. See
  [`docs/PhysicsAndFittingGuide.m`](docs/PhysicsAndFittingGuide.m) for the full derivation and
  worked examples, and [`reference/literature_case_studies.md`](reference/literature_case_studies.md)
  for validation against published outdoor-propagation data.

## Why this exists

Most open acoustics code (e.g. the Python
[`acoustics`](https://github.com/python-acoustics/python-acoustics) package this project used as
a cross-reference) either predates the current standard editions or has quietly-wrong corners —
we found and avoided one such bug in its time-weighting integrator (a pole that doesn't sit where
its own docstring claims; see [`CLAUDE.md`](CLAUDE.md) for details). Every function here is
implemented from the standard's actual equations and validated against the standard's own worked
numbers wherever the standard publishes any — not just "it runs without erroring."

## Standards implemented

| Standard | Edition used | What it covers |
|---|---|---|
| IEC 61672-1 | 2013 (current) | Sound level meters: A/C/Z weighting, Fast/Slow, Leq |
| IEC 61260-1 | 2014 (current) | Octave/fractional-octave band filters: frequencies, edges |
| ISO 9613-2 | 2024 (current) | Outdoor sound propagation, incl. Annex D (wind turbines) |
| ISO 9613-1 | 1993 (current) | Atmospheric absorption (used inside the 9613-2 module) |

> **Edition history:** the propagation module originally targeted ISO 9613-2:1996 (the only full
> text available at the time) and was updated to the current 2024 edition once that text became
> available, then fully reconciled clause-by-clause (including all four annexes) in a follow-up
> pass. The 2024 revision is a genuine formula change in several places, not just relabeling —
> most notably a non-linear ground-attenuation combination (`groundAttenuation.m`) replacing the
> 1996 plain sum, and a reworked barrier-diffraction formula (`barrierAttenuation.m`, caps
> confirmed unchanged at 20/25 dB). See `reference/iso_9613_2_2024_notes.md` for the full
> eq.-by-eq. comparison, including the pieces still not ported (multi-edge/lateral diffraction
> path variants, the detailed forestry-based foliage method, and Annex A's housing "Ahous,2" term,
> whose 2024 formula wasn't found in the reviewed text).

## Project structure

```
matlab/+noiseanalyzer/   MATLAB package — all the actual functions (one function per file,
                         named after what it computes, docstring cites the standard clause/
                         equation number it implements)
app/                     NoiseAnalyzerApp.m — the interactive GUI (see below)
tests/                   matlab.unittest test suite (runAllTests.m runs everything)
docs/                    PhysicsAndFittingGuide.m — interactive equations/physics walkthrough
                         (author as .m, convert to a Live Script .mlx for interactive use)
reference/               Formulas and cross-reference material used while building this
                         (see reference/README.md for what's here and what isn't, and why),
                         plus literature_case_studies.md (published-data validation)
CLAUDE.md                Working notes: design decisions, verification results, open items
```

## Requirements

- MATLAB (developed/tested on R2021b). No toolboxes required for the core acoustics/GUI
  functionality — deliberately: this was built on a machine without Signal Processing Toolbox, so
  the one thing that toolbox would normally provide (`bilinear`) is implemented from scratch in
  `bilinearTransform.m`.
- The source-power/ground-factor **fitting** feature uses Optimization Toolbox (`lsqnonlin`) by
  default, but automatically falls back to base-MATLAB `fminsearch` if that toolbox isn't
  licensed; `fmincon`/`ga`/`particleswarm` (Optimization / Global Optimization Toolbox) are
  available as alternative solvers but not required. 95% confidence intervals on the fit use
  Statistics and Machine Learning Toolbox when available, and are omitted (not estimated) if not.

## GUI app

`app/NoiseAnalyzerApp.m` is an interactive app for analyzing sound-pressure recordings from one or
more microphones at known distances from a source — load, trim, listen, analyze, compare across
distance, export.

```matlab
addpath('matlab'); addpath('app');
app = NoiseAnalyzerApp;
```

- **Add Microphone(s)...** — pick one or more CSV/TXT (with a `time`/`pressure` header, two
  unlabeled numeric columns, or a single pressure-only column) or MAT files at once; each becomes
  a row in the microphone table. Pressure-only files need a sample rate from Settings.
- **Microphone table** — one row per loaded recording: editable **Distance (m)** from the sound
  source and an **Include** checkbox (controls which mics count toward the aggregate — e.g. drop
  a mic that clipped or had wind noise without deleting it). Click a row to view/trim/hear that
  recording on the right.
- **Trim the time range** — numeric Start/End (s) fields under the waveform plot, applied via
  "Apply Trim"; the kept range is highlighted directly on the waveform (full recording in gray,
  selection in blue, boundaries marked). *(Not a mouse-draggable region — Image Processing
  Toolbox, which provides that, isn't available on the machine this was built on; numeric fields
  plus a highlighted plot were the toolbox-free alternative.)*
- **Play / Stop** — listen to the trimmed segment of the selected recording (normalized for
  playback; this is not SPL-calibrated audio, just a way to check "is this junk or signal").
- **Settings table** — a fixed, visible list (sample rate override, reference pressure, Fast/Slow
  time-weighting, aggregation method) rather than a free-text block, so it's clear how many
  settings there are; load/save as a `.csv` config file.
- **Analyze All** — computes LAeq/LCeq/LZeq, LAFmax/LASmax, LA10/LA50/LA90 and an FFT-based
  octave-band spectrum estimate (labeled as an estimate — the true IEC 61260-1 filterbank isn't
  built yet, see Roadmap) for every loaded microphone's trimmed segment. A status lamp shows
  busy (amber) vs. done (green) so you know when it's safe to continue.
- **Distance Analysis tab** — plot any metric vs. distance across included microphones, with
  per-distance-group aggregate markers (energetic mean, or max, grouped by a configurable
  distance tolerance) showing how the measured level falls off with distance. A **Propagation
  model** panel lets you set temperature/humidity/pressure, source/receiver height, ground factor
  and directivity, choose which of source power level (Lw) / ground factor (G) to fit (or hold
  fixed), pick a solver (`lsqnonlin` by default, with `fminsearch`/`fmincon`/`ga`/`particleswarm`
  also available), and click **Fit Model** to overlay the fitted ISO 9613-2 curve on the measured
  data plus a residuals plot (fitting works on the LAeq metric).
- **Export Summary + CSVs** — one combined `noise_analysis_summary.csv` (every microphone's
  metrics plus distance and include-flag, with an aggregate row appended), a per-microphone
  `<label>_timeseries.csv` (Fast A-weighted level vs. time), and, once a model has been fit,
  `propagation_fit.csv` (measured/predicted/residual per distance group) plus
  `propagation_fit_parameters.csv` (fitted Lw, G, RMSE, R², solver).

Written as a `uifigure`-based `classdef` app (the same object model App Designer itself generates)
rather than a packaged `.mlapp` binary, so it stays readable and diffable in source control. All
the actual computation lives in `noiseanalyzer.*` functions — the app class is a thin UI wrapper,
verified by testing those functions directly plus a full synthetic multi-microphone integration
test (see `CLAUDE.md`), confirming the app itself instantiates, and exercising the newer/riskier
graphics and table code paths (styled `xline`/`yline`, `scatter`, `uilamp`, CSV-backed tables)
standalone against realistic data.

For a single-recording, non-comparative workflow, the underlying `noiseanalyzer.writeAnalysisReport`
/ `writeSummaryCsv` / plain-text-settings functions from the app's first version are still present
and independently tested, just not wired into this multi-microphone GUI.

## Try it

`examples/` has two synthetic, precisely level-calibrated recordings to load into the app (as two
separate microphones, or one at a time) — including a 94 dB SPL calibration tone to sanity-check
the install — plus the expected analysis output for each. See `examples/README.md`.

For the source-power/ground-factor fitting feature specifically, `examples/multi_mic_experiment/`
has a full synthetic 8-microphone experiment (several mics per radius, several radii) with a known
ground-truth source power level and ground factor to fit against and check — see
`examples/multi_mic_experiment/README.md`.

## Usage

```matlab
addpath('matlab');

% A-weighted sound pressure level of a signal
p0 = noiseanalyzer.referencePressure();
Lp = noiseanalyzer.soundPressureLevel(pressureSignal, p0);

% Apply an A-weighting filter and get the Fast time-weighted level
fs = 48000;
weighted = noiseanalyzer.applyWeighting(pressureSignal, fs, "A");
[t, LpFast] = noiseanalyzer.timeWeightedLevel(weighted, fs, ...
    noiseanalyzer.timeWeightingConstants("FAST"));

% Outdoor propagation: octave-band level at a receiver 100 m from a source
bands = noiseanalyzer.iso9613OctaveBands();          % [63 125 250 500 1000 2000 4000 8000] Hz
alpha = noiseanalyzer.atmosphericAttenuationCoefficient(bands, 20, 70);  % 20 C, 70% RH
Adiv  = noiseanalyzer.geometricalDivergence(100);
Aatm  = noiseanalyzer.atmosphericAttenuation(alpha, 100);
Agr   = noiseanalyzer.groundAttenuation(bands, 0, 0, 0, 4, 1.5, 100);    % hard ground
Lw    = 100 * ones(1, numel(bands));                 % 100 dB source power, all bands
Lp    = noiseanalyzer.pointSourceOctaveBandLevel(Lw, 0, Adiv, Aatm, Agr);
LAT   = noiseanalyzer.aWeightedSoundPressureLevel(Lp, bands);

% Same scenario, one call (new): predict overall level at a distance directly
LAT2  = noiseanalyzer.predictedSoundPressureLevel(Lw, 100, 'TemperatureC', 20, ...
    'RelativeHumidityPct', 70, 'Gs', 0, 'Gr', 0, 'Gm', 0, 'hs', 4, 'hr', 1.5); % == LAT

% Fit an unknown source power level + ground factor to multi-mic measurements
distances = [10; 20; 40; 80; 160];
measuredLAeq = [95.2; 87.1; 78.6; 69.4; 60.9]; % one LAeq per distance (or per group, see below)
fit = noiseanalyzer.fitSourceLevelAndGroundFactor(distances, measuredLAeq);
fprintf('Fitted Lw=%.1f dB, G=%.2f (RMSE=%.2f dB)\n', fit.LwFit, fit.GFit, fit.RMSE);
```

## Tests

```matlab
addpath('tests');
runAllTests();  % matlab.unittest suite: propagation, inversion, and fit-recovery checks
```

## Roadmap

- [ ] Actual octave-band filterbank (true IEC 61260-1 band-pass filtering — the app's spectrum
      tab currently uses an FFT-based estimate instead, clearly labeled as such)
- [ ] ISO 1996-2:2017 tonal-adjustment / environmental-noise assessment logic
- [ ] ISO 9613-2's detailed forestry-parameter foliage method (Annex A.2.3) and the Annex A.4
      "Ahous,2" housing term (2024 formula not located in the reviewed text)
- [ ] Wire `barrierAttenuation.m` up to the default/general eq.(22)/(23) path-length method
      (currently uses the 7.4.2 "alternative method," eq.24, only) and to
      `combineBarrierDiffractionPaths` for lateral-diffraction paths (function exists, not yet
      called from a top-level orchestration function)
- [x] Update ISO 9613-2 ground-effect and barrier-diffraction formulas to the 2024 edition,
      confirming the 20 dB/25 dB barrier-attenuation caps are unchanged
- [x] ISO 9613-2 clause 7.5 (reflections, incl. multi-order and cylindrical surfaces) and Annex A
      foliage/industrial-site/housing (partial — see above), Annex B (chimney-stack directivity),
      Annex C (wind-distribution-based meteorological correction)
- [x] GUI app for analyzing a recorded signal — `app/NoiseAnalyzerApp.m`
- [x] Multi-microphone support: distance tracking, include/exclude, mean/max aggregation,
      level-vs-distance plot, time-range trimming, playback, busy/done status, CSV settings
      and output
- [x] Source power level estimation, forward ISO 9613-2 distance-attenuation prediction, and
      nonlinear fitting of source power / ground factor to multi-mic data, wired into the
      Distance Analysis tab with fitted-curve overlay + residuals plot
- [ ] Separate Gs/Gr/Gm (source/receiver/middle-region ground factor) as an advanced fitting
      option in the GUI — the underlying functions support it, only the app UI currently exposes
      a single lumped G to keep a typically-sparse multi-radius fit well-conditioned
- [ ] Per-octave-band fitting (needs a calibrated octave-band spectrum; the app's current
      spectrum tab is an FFT-based estimate, see above) — fitting currently works on overall LAeq
- [ ] Live/real-time level meter (the current GUI analyzes a loaded recording, not a live feed)
- [ ] Mouse-draggable trim selection (needs Image Processing Toolbox, not available here — see
      the GUI app section above for the numeric-field alternative actually used)

## License

MIT — see [LICENSE](LICENSE). Portions of the algorithm design were cross-checked against
[python-acoustics](https://github.com/python-acoustics/python-acoustics) (BSD-3-Clause); relevant
functions credit it in their docstrings. See [`reference/README.md`](reference/README.md) for a
note on what's deliberately *not* included here (copyrighted ISO standard text).
