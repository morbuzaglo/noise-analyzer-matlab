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
  diffraction (single and double), and meteorological correction, per **ISO 9613-2:1996**.

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
| ISO 9613-2 | 1996 (current is 2024 — see note below) | Outdoor sound propagation |
| ISO 9613-1 | 1993 (current) | Atmospheric absorption (used inside the 9613-2 module) |

> **Edition note:** ISO 9613-2:1996 was used because that's the edition we had direct access to
> the full text of. The current edition, ISO 9613-2:2024, reportedly revised ground-factor
> determination specifically. The 1996 method implemented here is complete and internally
> consistent on its own; reconciling it against the 2024 changes is open (see Roadmap).

## Project structure

```
matlab/+noiseanalyzer/   MATLAB package — all the actual functions (one function per file,
                         named after what it computes, docstring cites the standard clause/
                         equation number it implements)
reference/               Formulas and cross-reference material used while building this
                         (see reference/README.md for what's here and what isn't, and why)
CLAUDE.md                Working notes: design decisions, verification results, open items
```

## Requirements

- MATLAB (developed/tested on R2021b). No toolboxes required — deliberately: this was built on a
  machine without Signal Processing Toolbox, so the one thing that toolbox would normally provide
  (`bilinear`) is implemented from scratch in `bilinearTransform.m`.

## GUI app

`app/NoiseAnalyzerApp.m` is an interactive app for analyzing a raw sound-pressure recording
end-to-end: load data, configure settings, analyze, view plots, export a report + CSVs.

```matlab
addpath('matlab'); addpath('app');
app = NoiseAnalyzerApp;
```

- **Load Data** — CSV/TXT (with a `time`/`pressure` header, two unlabeled numeric columns, or a
  single pressure-only column) or MAT files. Pressure-only data needs a sample rate from Settings.
- **Settings** — plain-text `key = value` panel in the app (sample rate override, reference
  pressure, Fast/Slow time-weighting); load/save it as a `.txt` config file with the buttons
  below it — same format either way.
- **Analyze** — computes LAeq/LCeq/LZeq, LAFmax/LASmax, LA10/LA50/LA90 percentile levels, and an
  FFT-based octave-band spectrum estimate (explicitly labeled as an estimate — the actual
  IEC 61260-1 band-pass filterbank isn't built yet, see Roadmap).
- **Plots** — waveform, A-weighted level vs. time, octave-band spectrum, and a summary table, each
  in its own tab.
- **Export Report + CSV** — writes `<name>_report.txt` (human-readable summary),
  `<name>_timeseries.csv` (time, Fast A-weighted level), and `<name>_summary.csv` (metrics table)
  to the chosen output folder.

Written as a `uifigure`-based `classdef` app (the same object model App Designer itself generates)
rather than a packaged `.mlapp` binary, so it stays readable and diffable in source control. All
the actual computation lives in `noiseanalyzer.*` functions — the app class is a thin UI wrapper
and was verified by testing those functions directly (see `CLAUDE.md`), plus confirming the app
itself instantiates and its plotting/table code paths run without error.

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
```

## Roadmap

- [ ] Actual octave-band filterbank (true IEC 61260-1 band-pass filtering — the app's spectrum
      tab currently uses an FFT-based estimate instead, clearly labeled as such)
- [ ] ISO 1996-2:2017 tonal-adjustment / environmental-noise assessment logic
- [ ] ISO 9613-2 clause 7.5 (reflections) and Annex A (foliage/industrial-site/housing terms)
- [ ] Reconcile ISO 9613-2 ground-effect terms against the 2024 edition
- [x] GUI app for analyzing a recorded signal — `app/NoiseAnalyzerApp.m`
- [ ] Live/real-time level meter (the current GUI analyzes a loaded recording, not a live feed)

## License

MIT — see [LICENSE](LICENSE). Portions of the algorithm design were cross-checked against
[python-acoustics](https://github.com/python-acoustics/python-acoustics) (BSD-3-Clause); relevant
functions credit it in their docstrings. See [`reference/README.md`](reference/README.md) for a
note on what's deliberately *not* included here (copyrighted ISO standard text).
