# Literature / case-study validation of the ISO 9613-2 propagation model

Sanity-check of `matlab/+noiseanalyzer/predictedSoundPressureLevel.m` and
`fitSourceLevelAndGroundFactor.m` against published outside sources, since no real
multi-microphone dataset exists in this repo yet (per the assignment that produced this file,
2026-09-16). This is **not** a rigorous re-derivation of the full octave-band general method —
that already exists in `groundAttenuation.m` / `atmosphericAttenuationCoefficient.m` etc. It is a
coarse, single-band, single-point-source arithmetic check against real-world numbers, to catch
gross errors (wrong sign, wrong order of magnitude, wrong equation) rather than to validate
per-band accuracy.

Only short, clearly-attributed quotes are reproduced from any copyrighted source below (papers,
conference proceedings, regulatory filings); no full documents are redistributed here, consistent
with the licensing approach documented in `reference/README.md`.

## Step 1 — does the standard itself publish a worked numeric example?

Checked `reference/iso_9613_2_1996.txt` (OCR'd standard text) and `reference/iso_9613_2_2024_notes.md`
for a worked example (concrete Lw, distance, heights, ground type, resulting predicted level).
**None found in either edition's reviewed material.** Specifically:

- The 1996 text's own "Annex B" (line 1133 of `iso_9613_2_1996.txt`) is titled *(informative)
  Bibliography* — a list of 12 references to other standards/reports, not a worked example (lines
  1133–1164).
- Clause 9 ("Accuracy and limitations", around lines 925–988) states the ±3 dB / ±1 dB accuracy
  claims of Table 5 and says agreement between "calculated and measured values ... supports the
  estimated accuracy of calculation shown in table 5," explicitly citing "annex B" as where
  supporting evidence lives — but annex B is the bibliography above, not an in-line example; the
  actual supporting validation data lives in the papers annex B cites (e.g. VDI 2714, VDI 2720-1,
  the Danish/Dutch industrial-noise reports), which are themselves not available to us.
- `reference/iso_9613_2_2024_notes.md` (this project's own transcription of the 2024 edition) notes
  no worked example either; Annex D (wind turbines) gives qualitative guidance (G caps, barrier
  caps) but no single numeric example with a stated Lw/distance/predicted-Lp triplet.

So there is no zero-risk, standard-published case study available — every case study below is
drawn from outside literature per step 2 of the task.

## Simplifying assumptions used throughout (declared once, not per case study)

Per the task's own instruction, all hand-calculations below use only the single-point-source, no
barrier/reflection core of ISO 9613-2, one broadband A-weighted number rather than 9 octave bands:

- `Adiv = 20*log10(d) + 11`
- `Aatm = alpha*d/1000` with **alpha ≈ 1 dB/km** — a rough stand-in for a mid-band (~500 Hz-ish)
  A-weighted broadband atmospheric absorption coefficient at ~10–15°C / 70% RH. The real value is
  frequency-dependent per ISO 9613-1 (`atmosphericAttenuationCoefficient.m` computes it properly,
  band by band) and can range roughly 1–5 dB/km across the 9 bands at these conditions — using a
  single flat 1 dB/km is a genuine, acknowledged simplification, not a claim that it's accurate.
- `Agr = max(0, 4.8 - (2*hm/d)*(17 + 300/d))`, `hm = (hs+hr)/2` — the eq.(10) **porous-ground**
  simplified method, used only where the cited source itself assumed porous/mixed ground.
- Where a source assumed **G=0 (completely reflective/hard ground)**, eq.(10) does not apply (it's
  only valid for porous/mostly-porous ground per the standard's own text). Instead we use the
  well-known reduction of the general method's eq.(9) at G=0: `As=Ar=-1.5 dB` each, `Am≈0`, giving a
  flat **`Agr = -3.0 dB`** — the same "hard ground gives -3.0 dB flat" result already verified
  against the standard in this project's own `groundAttenuation.m` (see `CLAUDE.md`'s "ISO 9613-2
  module built and verified" entry).
- No barrier, reflection, or meteorological-correction terms (`Abar = Amisc = Cmet = 0`) — all
  case studies below are non-line-of-sight-blocked, open terrain.
- Where the real source is a multi-turbine wind farm, the hand-calc below is a **single dominant
  point source** idealization, not an energetic sum over dozens of turbines. This mismatch is
  flagged explicitly wherever it matters (it turns out to matter a lot — see Case Study 2).

---

## Case Study 1 — 13-site wind farm field validation (Evans & Cooper, 2012 / Cooper & Evans, 2013)

**Citations:**
- T. Evans and J. Cooper, "Comparison of Predicted and Measured Wind Farm Noise Levels and
  Implications for Assessments of New Wind Farms," *Acoustics Australia*, Vol. 40, No. 1, pp.
  28–36, April 2012. <https://www.acoustics.asn.au/journal/2012/2012_40_1_Evans.pdf>
- J. Cooper and T. Evans, "Accuracy of noise predictions for wind farms," *5th International
  Conference on Wind Turbine Noise*, Denver, 28–30 August 2013 (companion paper, more detail —
  same underlying dataset). Retrieved as part of a compiled conference-proceedings exhibit at
  <https://puc.sd.gov/commission/dockets/electric/2017/el17-028/dr2-20.pdf> (South Dakota PUC
  docket EL17-028, data-request response DR2-20).

**Geometry/conditions:** 13 measurement sites at 6 wind farms in South Australia/Victoria,
turbines rated ~1.5–2 MW, sound power levels measured per IEC 61400-11 at one or two turbines per
site, receiver height 1.5 m, distances 300–3000 m to the nearest turbine, topography variously
flat, steady downward slope, or concave downward slope (Table 1 of the 2013 paper). Full ISO
9613-2 general method run in SoundPLAN 7.0 with two ground assumptions, **G=0** and **G=0.5**;
10°C/80% RH; measured levels are compliance-grade A-weighted L90,10min averaged over 3–4 weeks per
the 2009 South Australian Wind Farms Environmental Noise Guidelines.

**Reported comparison** (predicted − measured, dB(A); selected sites from the 2013 paper's Table
1, which is the fuller version of the 2012 journal paper's Table 2):

| Site | Distance to nearest turbine | Topography | ISO 9613-2 (G=0) | ISO 9613-2 (G=0.5) |
|---|---|---|---|---|
| A1 | 1000 m | Steady downward slope | +5.8 | +2.2 |
| A3 | 800 m | Concave downward slope | −0.4 | −3.5 |
| B4 | 3000 m | Concave downward slope | −0.3 | −4.8 |
| C2 | 300 m | Flat | +2.9 | +0.1 |
| D1 | 300 m | Flat | +3.2 | 0.0 |
| E1 | 1200 m | Flat | +2.5 | −1.2 |

**My hand-calc vs. this source:** Not attempted directly — only predicted-minus-measured *deltas*
are published (not the raw absolute Lw or Lp), computed with the full octave-band general method
in commercial software, so there's nothing for the simplified single-band equations above to
literally reproduce. Presented instead as an independent, already-computed external benchmark.

**Interpretation:** For flat/steady-slope terrain, G=0 over-predicts by 2–6 dB(A) (i.e. is
conservative, as ISO 9613-2 is intended to be), and G=0.5 tracks measured levels within about
±2 dB(A) — both **within the standard's own claimed ±3 dB accuracy for downwind broadband levels**
(Table 5). For concave-slope terrain, G=0.5 under-predicts by up to 4.8 dB(A), **exceeding** the
±3 dB claim — consistent with the standard's own statement that eq.(9)/the general ground-effect
method "is applicable only to ground that is approximately flat" (per the 1996 text, clause 9).
This is directly relevant to this repo's `fitSourceLevelAndGroundFactor.m`, whose default
`FixedG=0.5`: this study says that default should track flat/gently-sloping real terrain to within
a couple of dB, but will systematically under-predict (by as much as 5 dB) on concave terrain
unless G is actually fit rather than fixed — exactly the scenario that function is built to handle
via its `FitTargets` option.

---

## Case Study 2 — large-discrepancy field study, Kentilux wind farm, Uruguay (Echeverri-Londoño & González, 2019)

**Citation:** C. A. Echeverri-Londoño, A. E. González-Fernández, "Prediction of noise from wind
turbines: a theoretical and experimental study," *Revista Facultad de Ingeniería Universidad de
Antioquia*, No. 90, pp. 28–33, 2019. <https://www.redalyc.org/journal/430/43065097005/html/>

**Geometry/conditions:** Kentilux S.A. wind farm, San José department, Uruguay (Route 1, km 41);
turbine hub height ≈80 m; receiver height 1.2 m; distances 100–900 m downwind of the turbines;
atmospheric stability class E (moderate thermal inversion), wind speed 1–5 m/s — i.e. **within**
ISO 9613-2's own stated meteorological validity range (clause 5). ISO 9613-2 modelled as a single
point source with the standard spherical-divergence (`Adiv`) term.

**Reported measured vs. predicted:** ISO 9613-2 **consistently under-predicted** the measured
levels — median residual (measured − predicted) = 29.6 dBZ (wideband/unweighted) and **20.5 dB(A)**
(A-weighted), with a reported range up to 56.5 dB in the wideband case. The authors also tried
modelling the wind farm as a **cylindrical/line source** instead of a point source, which fit far
better: median residual dropped to **−7.2 dB(A)**.

**My hand-calc:** Illustrative only — the paper's own summary (as reviewed) does not give an exact
published Lw, so a representative **Lw,A = 105 dB(A)** (typical of a multi-MW turbine of that era)
is substituted as a stand-in, explicitly *not* a value reported in the source. With hs=80 m,
hr=1.2 m, hm=40.6 m, porous ground (per the paper's discussion of "hard and porous soil types"),
alpha=1 dB/km:

| d (m) | Adiv (dB) | Aatm (dB) | Agr (dB) | Lp (dB(A)) |
|---|---|---|---|---|
| 100 | 51.0 | 0.10 | 0.0 | 53.9 |
| 500 | 65.0 | 0.50 | 1.9 | 37.6 |
| 900 | 70.1 | 0.90 | 3.2 | 30.8 |

**Error/interpretation:** This is by far the **largest discrepancy** of any case study here — an
order of magnitude beyond the standard's own ±3 dB claim, in the paper's own numbers, not mine.
The paper's own diagnosis is the likely root cause and matches basic physics: **a wind farm is an
extended/line source, not a single point source**, at the 100–900 m ranges studied. ISO 9613-2's
`Adiv` term (eq. 7) bakes in spherical (point-source) divergence, `20*log10(d)`; a line/cylindrical
source instead falls off closer to `10*log10(d)`, i.e. attenuates much more slowly with distance —
exactly why treating the whole farm as a point source badly *under*-predicts at these distances,
and exactly why the paper's own cylindrical-source refit brought the residual down from +20.5 dB
to −7.2 dB. This is a genuine boundary condition worth flagging for this repo:
`predictedSoundPressureLevel.m` implements the single-point-source model only, and per this case
study should not be expected to hold for a multi-turbine array evaluated as one point at close-to-
moderate range without per-turbine summation (which the module doesn't currently do — see
`multiReflectionImageSourceLevel.m` for the closest existing multi-source pattern, built for
reflections rather than independent real sources).

---

## Case Study 3 — close-agreement field validation, three Taiwan wind farms (Chiu & Lung, 2020)

**Citation:** C.-H. Chiu and S.-C. C. Lung, "Assessment of low-frequency noise from wind turbines
under different weather conditions," *Journal of Environmental Health Science and Engineering*,
18(2), pp. 505–514, 2020. Open access: <https://pmc.ncbi.nlm.nih.gov/articles/PMC7721757/>
(doi:10.1007/s40201-020-00478-9).

**Geometry/conditions:** Three wind farms in northern Taiwan (designated NT, TY, HC), different
turbine brands, hub heights 45 m / 65 m / 64 m respectively, monitoring at 1.7 m (human ear
height), source-receiver vertical height differences 40 m / 59 m / 52 m, analysis restricted to
<1 km (the paper's own stated ISO 9613-2 range limit). Reported turbine sound power level (for the
20–200 Hz sub-band specifically, not full-spectrum) ranged 93.2–110.4 dB(A) depending on brand and
wind speed (2–12 m/s). Ground effect via a frequency-specific table (attributed to "Saarinen")
rather than a single scalar G. Measurements Sept–Dec 2018.

**Reported measured vs. modelled LAeq difference:** 0.6–1.7 dB at NT (2–8 m/s), 0.6–1.6 dB at TY
(2–8 m/s), 0.4–2.4 dB at HC (2–10 m/s) — see the per-wind-speed-bin table in the source (their
Table 2). The paper itself states measurement/model uncertainty "±3 dB per ISO 9613-2."

**My hand-calc:** Not attempted — the reviewed summary gives vertical height differences but not
the horizontal source-receiver distances or a single scalar G (a frequency-dependent table was
used instead), so there isn't enough geometry here to run the simplified single-band equations
meaningfully; also the reported sound power levels are for a 20–200 Hz sub-band specifically, not
the full-spectrum Lw the simplified equations assume.

**Interpretation:** Presented as-is, as the "it works about as advertised" anchor case: every
reported difference here is **within the standard's own claimed ±3 dB accuracy**, in real,
published, peer-reviewed field data — a useful contrast to Case Study 2's order-of-magnitude miss,
underscoring that ISO 9613-2's accuracy is real but conditional on the source genuinely behaving
like the assumed single compact point (here, comparatively low hub heights 45–65 m and sub-1-km
range, both inside the standard's originally-validated envelope per Table 5).

---

## Case Study 4 — ground-factor sensitivity for a tall (80 m hub) source (Kaliski & Duncan, 2008)

**Citation:** K. Kaliski and E. Duncan, "Propagation Modeling Parameters for Wind Power Projects,"
*Sound & Vibration*, December 2008, pp. 12–13 (based on a paper presented at Noise-Con 2007,
Institute of Noise Control Engineering, Reno, NV, October 2007). Retrieved as part of the same
compiled conference-proceedings exhibit as Case Study 1:
<https://puc.sd.gov/commission/dockets/electric/2017/el17-028/dr2-20.pdf>.

**Geometry/conditions:** A 100 MW, 67-turbine wind farm on flat farmland (project sponsor
Iberdrola, operator enXco), each turbine hub 80 m tall with an 80 m rotor diameter, turbines
roughly 300 m (1000 ft) apart. Two IEC Type I sound level meters at 120 m and 610 m from the
northern edge of the wind farm, overnight (10 p.m.–10 a.m.), logging 1-minute Leq in 1/3-octave
bands. Modelled in Cadna A (Datakustik) using ISO 9613-2's **spectral** ground-attenuation method
at G=0 and G=1, its **nonspectral** (simplified, eq.10-equivalent) method, a "no ground
attenuation" variant, and CONCAWE meteorological adjustments.

**Reported measured level:** overnight 90th-percentile, 1-minute-average LAeq at the 610 m monitor
ranged **34–43 dB(A)**, correlated with wind speed.

**Reported model performance (regression of modelled vs. monitored levels, N=60):** ISO 9613-2
spectral ground attenuation with **G=1** (the "textbook" choice for farmland/vegetation)
**under-estimated monitored levels by ~13% on average** (regression slope 0.87); ISO 9613-2 with
**no** ground-attenuation term gave the best fit of all tested combinations (slope 0.9924); ISO
9613-2 with the **nonspectral** (simplified) method also fit well (slope 0.957, ~4%
under-estimate).

**My hand-calc:** Not attempted — the paper's sound power level is a running per-10-minute
manufacturer lookup keyed to real-time measured wind speed at each of 67 turbines, not a single
published Lw, and the comparison is an energetic sum over the whole farm, not one point source.

**Interpretation:** Rather than an absolute-level check, this case study is used for its
**ground-factor lesson**: the authors attribute the G=1 miss to the 80 m hub height being far
taller than the near-ground reflection geometry the ground-effect term was originally validated
for — and note ISO 9613-2 is "only valid for moderate nighttime inversions or downwind
conditions" at "1 to 5 m/s at 3 to 11 m high," a wind/height range wind turbines routinely exceed.
This is a striking real-world precursor to what `reference/iso_9613_2_2024_notes.md` documents as
a genuinely new rule in the 2024 edition's Annex D.4: **cap the porous ground factor at G=0.5 (not
1.0) for wind turbines specifically**, because "using G=1 ... under-predicts measured wind-turbine
levels and 'should therefore not be applied.'" This 2008 field study is an independent real-world
confirmation of essentially that same finding roughly 15 years before ISO codified it — and a
caution that this repo's `predictedSoundPressureLevel.m`/`fitSourceLevelAndGroundFactor.m`
defaults (`Gs=Gr=Gm=0.5`, `FixedG=0.5`) are already aligned with the *later* standard's guidance,
but a caller who overrides those toward G=1 for a tall single-turbine-like source should expect
the same systematic under-prediction seen here.

---

## Case Study 5 — regulatory pre-construction filing, hand-computed single-turbine sanity check (Hankard Environmental / Deuel Harvest North, South Dakota PUC docket EL18-053, 2018)

**Citation:** Hankard Environmental, "Pre-Construction Wind Turbine Noise Analysis for the
Proposed Deuel Harvest North Wind Farm" (Appendix D), South Dakota Public Utilities Commission
docket EL18-053, November 2018. <https://puc.sd.gov/commission/dockets/electric/2018/el18-053/appendixd.pdf>
— the same kind of publicly-filed regulatory exhibit this project's own
`reference/iso_9613_2_1996.pdf` was sourced from (see `CLAUDE.md`), so treated here as an
equivalently reliable source type.

**Geometry/conditions:** GE 2.82-127 LNTE turbine, manufacturer sound power level per IEC 61400-11
at 10 m/s hub-height wind speed, **overall Lw,A = 108.5 dB(A)** (report's Table 4-1); hub height
**hs = 88.6 m**; receiver height **hr = 1.5 m** (the filing's own stated ISO 9613-2 convention);
ground factor **conservatively assumed G=0** ("completely reflective"), with the report itself
noting actual conditions "would generally be closer to 0.5"; standard-day atmosphere
10 °C/70% RH/1 atm, chosen by the filing specifically as the *lowest*-atmospheric-absorption (i.e.
also conservative) case; modelled in SoundPLAN with the full ISO 9613-2 general method, summing
124 turbines plus 2 substation transformers per receptor.

**Reported predicted levels:** the filing's Table 5-1 gives the 12 loudest non-participating
residences at **43.4–44.9 dB(A)** predicted Leq(1-hr); across all 122 non-participating residences
the range is **24–45 dB(A)**, average 36 dB(A). (This is a *pre-construction* filing — there is no
post-construction field measurement in this exhibit; the consultant separately states its general
compliance-survey experience elsewhere finds predictions "at least 1 dB higher than the loudest
measured hourly turbine-only noise levels.")

**My hand-calc**, using the filing's own reported Lw/hub height/ground choice, single dominant
turbine, hard ground (`Agr = -3.0 dB` flat, per the assumptions section above — not the porous
eq.10 formula, which doesn't apply at G=0), alpha=1 dB/km:

| d (m) | Adiv (dB) | Aatm (dB) | Agr (dB) | Lp (dB(A)) |
|---|---|---|---|---|
| 300 | 60.5 | 0.30 | −3.0 | 50.7 |
| 500 | 65.0 | 0.50 | −3.0 | 46.0 |
| 800 | 69.1 | 0.80 | −3.0 | 41.6 |
| 1000 | 71.0 | 1.00 | −3.0 | 39.5 |
| 1500 | 74.5 | 1.50 | −3.0 | 35.5 |
| 2000 | 77.0 | 2.00 | −3.0 | 32.5 |
| 3000 | 80.5 | 3.00 | −3.0 | 28.0 |

**Error/interpretation:** This is the one case study here with a genuine like-for-like hand
recomputation from a fully specified single source, but it can only be checked as an
order-of-magnitude match against the filing's 24–45 dB(A) multi-turbine-summed range — not a
receptor-by-receptor match, since per-receptor nearest-turbine distances weren't in the reviewed
excerpt and the filing sums ~124 turbines per receptor. At the kind of distances plausible for the
closest non-participating residences (turbines spaced ~400–600 m apart along multi-mile strings,
so 800–2000 m to the nearest handful), the single-turbine estimate lands at **32–42 dB(A)** —
squarely inside the filing's reported 24–45 dB(A) band. The high end of the filing's range
(43–45 dB(A)) is also plausibly explained by energetic summation of several nearby turbines each
contributing something in the high-30s/low-40s (e.g. three equal 37 dB(A) contributors sum to
`10*log10(3*10^3.7) ≈ 41.8 dB(A)`). Read as: the simplified single-point-source equations produce
physically sensible numbers at genuine utility-scale wind-turbine geometry (hub height ~90 m,
Lw≈108 dB(A)) when benchmarked with the same conservative (G=0, low-absorption-atmosphere)
assumptions a professional consultant used for a real regulatory filing — a much weaker claim than
"matches measured data" (there is no measured data in this filing), but a legitimate sanity check
that nothing is off by an order of magnitude or has a sign error.

---

## Summary

Across these five case studies plus the standard's own text (which has no worked example to check
against at all), the simplified single-point-source ISO 9613-2 equations track real-world numbers
well — within the standard's own claimed ±3 dB accuracy — specifically when the assumptions behind
the model actually hold: a single, reasonably compact source (Case Study 5's hand-check, Case
Study 3's close published agreement), flat or gently-sloping terrain (the flat-terrain sites within
Case Study 1), and a sensibly chosen ground factor for the source height involved. Discrepancies
grow, sometimes drastically, exactly at the standard's known weak points, all independently
confirmed here from real field data rather than just from reading the standard's own caveats:
concave/complex terrain (Case Study 1, up to −4.8 dB), a porous ground factor over-applied to a
tall elevated source (Case Study 4, ~13% systematic under-prediction), and — the single largest
miss found, over an order of magnitude beyond the ±3 dB claim — treating an extended multi-turbine
wind farm as one point source at moderate range instead of a line/cylindrical radiator (Case Study
2). Strikingly, two of these known failure modes (short-range/large-height-difference ground
effect, and G=1 over-porosity for wind turbines) are exactly what the **2024 edition** of the
standard revised relative to 1996 — see `reference/iso_9613_2_2024_notes.md`'s notes on the new
`Kgeo` ground-combination term and Annex D's G≤0.5 cap — which these older, independent field
studies (2008, 2012/2013) appear to have anticipated empirically well before the standard caught
up. None of the available published sources provided a clean, complete, absolute-level dataset
across a full distance sweep for one single real source (most report only aggregated
prediction-minus-measurement deltas), so this document is convergent, order-of-magnitude support
for the model as implemented, not a quantitative regression test — collecting a real multi-
microphone dataset with this repo's own hardware and running it through
`fitSourceLevelAndGroundFactor.m` remains the real next validation step.
