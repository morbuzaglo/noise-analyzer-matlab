# Example data

Two **synthetic** example recordings for trying out `app/NoiseAnalyzerApp.m` — not real
measurements, generated and precisely level-calibrated using this package's own (verified)
functions, so the expected results are known exactly rather than approximately. See
`expected_output/` for what the app should produce.

## `calibration_tone_94dB_1kHz.csv`

A pure 1 kHz tone at exactly 94 dB SPL — the standard acoustic calibrator reference level (what
you'd use to check a real sound level meter). 2 s, 48 kHz, `time,pressure` columns.

**Expected result:** LAeq ≈ 94.0 dB (A-weighting is ~0 dB at 1 kHz, so LCeq/LZeq should also read
~94.0 dB). Good first thing to load — if your app doesn't reproduce this, something's wrong with
the install, not the data. Spectrum tab should show essentially all energy in the 1000 Hz band.

## `sample_environmental_recording.csv`

12 s, 24 kHz, synthetic broadband background noise at a calibrated 50 dB(A) (LAeq) with three
louder "event" bursts overlaid (Gaussian-enveloped broadband noise, not any particular real-world
sound — think of them as generic loud events, not specifically vehicle pass-bys or anything else)
at t≈3.5s (peak ~68 dB), t≈6.5s (peak ~72 dB, the loudest), and t≈9.8s (peak ~65 dB). Demonstrates
a more interesting Level-vs-Time trace and percentile spread than the pure tone.

**Expected result** (see `expected_output/sample_environmental_recording_report.txt` for exact
figures from this package's own analysis): LAeq ≈ 65 dB, LAFmax ≈ 72 dB (the loudest event), LA90
≈ 50 dB (background level — LA90 is "exceeded 90% of the time," i.e. the quiet baseline), LA10 ≈
70 dB (dominated by the louder events).

## `expected_output/`

The `.txt` report and summary `.csv` this package's own `analyzeRecording` /
`octaveBandSpectrumFFT` produce for each file above — generated the same way the app itself would,
so you can compare your own run's numbers against these directly.
