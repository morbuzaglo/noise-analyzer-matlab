# Synthetic multi-microphone experiment

A full **synthetic** multi-microphone dataset for exercising the app's Distance Analysis /
source-power-and-ground-factor fitting feature end to end, since no real field experiment exists
in this repo yet. Generated the same way `examples/`'s other files are — with this package's own
(verified) functions, so the "correct" answer is known exactly rather than approximately.

8 microphones, mimicking a real layout: several sharing (approximately) the same radius from the
source, several at different radii, with small realistic jitter in both actual distance and
measured level (not perfectly on the theoretical curve — a real experiment never is).

## Files

| File | Label | Distance to enter in the app (m) |
|---|---|---|
| `mic01_10m_A.csv` | mic01_10m_A | 9.8 |
| `mic02_10m_B.csv` | mic02_10m_B | 10.3 |
| `mic03_25m_A.csv` | mic03_25m_A | 24.5 |
| `mic04_25m_B.csv` | mic04_25m_B | 25.6 |
| `mic05_50m.csv`   | mic05_50m   | 50.0 |
| `mic06_100m_A.csv`| mic06_100m_A| 98.0 |
| `mic07_100m_B.csv`| mic07_100m_B| 103.0 |
| `mic08_200m.csv`  | mic08_200m  | 200.0 |

(Same numbers as `manifest.csv`, which also has each mic's target LAeq if you want to check a
single microphone's analysis in isolation before running the full multi-mic fit.)

Each file is a 4 s, 8 kHz, `time,pressure` CSV — a calibrated 1 kHz tone (A-weighting is ~0 dB at
1 kHz, same trick used by `examples/calibration_tone_94dB_1kHz.csv`, so the level you set is
almost exactly the LAeq you'll measure) at the level ISO 9613-2 predicts for the ground truth
below, plus small random measurement noise (0.4 dB std) so it behaves like a real, slightly-noisy
experiment rather than a mathematically perfect curve.

## Ground truth (the "answer key")

Generated with:
- **Source sound power level Lw = 100.0 dB** (flat spectrum)
- **Ground factor G = 0.62** (moderately porous ground)
- Temperature 15°C, relative humidity 70%, source height 1.5 m, receiver height 1.5 m, no
  directivity correction, no meteorological correction — i.e. the app's own default Propagation
  Model panel values.

## How to use it

1. Open the app (`app = NoiseAnalyzerApp;`), click **Add Microphone(s)...**, and select all 8
   `.csv` files here at once.
2. In the microphone table, set each row's **Distance (m)** to the value in the table above.
3. Click **Analyze All**.
4. Go to the **Distance Analysis** tab, leave the metric as **LAeq**.
5. In the **Propagation model** panel, the defaults (15°C, 70% RH, 101.325 kPa, hs=hr=1.5 m,
   G=0.5, Dc=0) already match the ground truth conditions except G — leave **Fit Lw** and
   **Fit G** both checked and click **Fit Model**.
6. Compare the fitted **Lw** and **G** shown in the results label against the ground truth above.

**What to expect:** the fit should land close to Lw≈100 dB (typically within ~1 dB) with a low
RMSE (well under 1 dB) and high R². The ground factor G is inherently harder to pin down than Lw
from a modest number of microphones — in the reference run used to build this dataset, `lsqnonlin`
recovered Lw=99.6 dB and G=0.47 against the true 100.0 dB / 0.62 (RMSE 0.40 dB, R²=0.998). Don't
expect G to land exactly on 0.62; a few tenths off is normal and matches what real field studies
find too (see `reference/literature_case_studies.md`) — Lw is the well-constrained parameter here,
G is the more uncertain one.

## Regenerating

Built by a one-off script (not checked into the repo, since it's not part of the app itself) that
calls `noiseanalyzer.predictedSoundPressureLevel` at each distance with the ground truth above,
adds `0.4 * randn()` dB of noise (seeded `rng(2026)` for reproducibility), and synthesizes a
matching-level 1 kHz tone per microphone via
`noiseanalyzer.referencePressure() * 10^(level/20) * sqrt(2) * sin(2*pi*1000*t)`.
