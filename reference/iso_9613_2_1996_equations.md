# ISO 9613-2:1996 — key equations (hand-verified against scanned page images)

Source: `iso_9613_2_1996.pdf` (full scanned standard, 24 pp., OCR text also at
`iso_9613_2_1996.txt`). The OCR text layer garbled most of the typeset equations (they came
through as blank `... (N)` markers) — the formulas below were transcribed by reading the actual
page images (pages 8, 9, 11, 12, 13, 14 of the PDF) and are the ones to implement against, not the
`.txt` file for anything with a `(N)` equation number. Prose, definitions, and tables not listed
here came through the OCR cleanly and are reliable in the `.txt` file.

Note: this is the **1996 first edition**. Current edition is **ISO 9613-2:2024**, which reportedly
revises ground-factor determination specifically (per ST-LINE blog / ISO catalog notes found
2026-09-14) — the equations below are the 1996 baseline, not yet reconciled against 2024 changes.

## Basic equations (clause 6)

- Eq(1): `L_p = 10 lg[(1/T) ∫ p_A(t)²/p0² dt]` — equivalent continuous A-weighted SPL, p0 = 20 µPa.
- Eq(3): `L_fT(DW) = Lw + Dc - A` — downwind octave-band SPL at receiver from one point source.
- Eq(4): `A = Adiv + Aatm + Agr + Abar + Amisc` — total octave-band attenuation.
- Eq(5): `L_AT(DW) = 10 lg{ Σ_i Σ_j 10^(0.1*[L_fT(i,j) + A_f(j)]) }` — sum over sources/paths i and
  octave bands j, A_f = standard A-weighting per band.
- Eq(6): `L_AT(LT) = L_AT(DW) - Cmet` — long-term average from downwind value.

## 7.1 Geometrical divergence

- Eq(7): `Adiv = 20*lg(d/d0) + 11` dB, d0 = 1 m reference distance.

## 7.2 Atmospheric absorption

- Eq(8): `Aatm = alpha*d/1000` dB, alpha = table 2 coefficient (dB/km) — see ISO 9613-1 for values
  outside table 2's conditions. (Already covered by `reference/iso_9613_1_1993.py`.)

## 7.3 Ground effect

Three regions: source region (30·hs from source, capped at dp), receiver region (30·hr from
receiver, capped at dp), middle region (remainder, if any). Ground factor G: hard ground G=0,
porous G=1, mixed G∈[0,1] = porous fraction.

- Eq(9): `Agr = As + Ar + Am` (general method, per-octave-band, Table 3 below).
- Table 3 (As/Ar, using G=Gs,h=hs for As; G=Gr,h=hr for Ar; dp = source-receiver distance
  projected onto ground plane):
  - 63 Hz: `As|Ar = -1.5`; `Am = -3q`
  - 125 Hz: `As|Ar = -1.5 + G*a'(h)`
  - 250 Hz: `As|Ar = -1.5 + G*b'(h)`
  - 500 Hz: `As|Ar = -1.5 + G*c'(h)`
  - 1000 Hz: `As|Ar = -1.5 + G*d'(h)`; `Am = -3q(1-Gm)` (this Am formula applies at 1000 Hz per
    the table; 63 Hz Am uses -3q with no (1-Gm) factor — table shows a single merged Am column
    spanning 125 Hz-8000Hz = -3q(1-Gm), with 63 Hz's Am = -3q as its own row)
  - 2000/4000/8000 Hz: `As|Ar = -1.5*(1-G)`
  - where:
    - `a'(h) = 1.5 + 3.0*exp(-0.12*(h-5)^2)*(1-exp(-dp/50)) + 5.7*exp(-0.09*h^2)*(1-exp(-2.8e-6*dp^2))`
    - `b'(h) = 1.5 + 8.6*exp(-0.09*h^2)*(1-exp(-dp/50))`
    - `c'(h) = 1.5 + 14.0*exp(-0.46*h^2)*(1-exp(-dp/50))`
    - `d'(h) = 1.5 + 5.0*exp(-0.9*h^2)*(1-exp(-dp/50))`
    - `q = 0` when `dp <= 30*(hs+hr)`; `q = 1 - 30*(hs+hr)/dp` when `dp > 30*(hs+hr)`
- Eq(10) (alternative, A-weighted only, porous/mostly-porous ground, non-tonal source):
  `Agr = max(0, 4.8 - (2*hm/d)*(17 + 300/d))` dB, hm = mean propagation-path height above ground
  (Fig. 3: hm = F/d, F = area between path and ground profile).
- Eq(11) (ground-reflection directivity term Domega, required in Dc when using eq.10):
  `Domega = 10*lg{1 + [dp² + (hs-hr)²]/[dp² + (hs+hr)²]}` dB.

## 7.4 Screening (barrier)

Applies when: surface density >= 10 kg/m², closed surface (no large gaps), and horizontal
dimension normal to source-receiver line > wavelength (l1+lr > lambda).

- Eq(12): `Abar = Dz - Agr > 0` — top-edge diffraction (downwind); note the two `Agr` terms cancel
  when substituted into eq.4, so `Dz` here already includes the ground effect *with* the barrier
  present.
- Eq(13): `Abar = Dz > 0` — vertical-edge (lateral) diffraction.
- Eq(14): `Dz = 10*lg[3 + (C2/lambda)*C3*z*Kmet]` dB.
  - `C2 = 20` normally; `C2 = 40` if ground reflections are separately handled via image sources.
  - `C3 = 1` for single diffraction.
  - Eq(15): `C3 = [1 + (5*lambda/e)^2] / [(1/3) + (5*lambda/e)^2]` for double diffraction, e =
    distance between the two diffraction edges (continuous transition: e=0 -> C3=1, e>>lambda ->
    C3=3).
  - `lambda` = sound wavelength at the octave band's nominal midband frequency (lambda = 340/f).
  - `z` = diffracted-minus-direct pathlength difference:
    - Eq(16) single diffraction: `z = sqrt((dss+dsr)^2 + a^2) - d` (negative if line-of-sight
      passes above the barrier top).
    - Eq(17) double diffraction: `z = sqrt((dss+dsr+e)^2 + a^2) - d`.
    - `dss` = source-to-(first)-edge distance, `dsr` = (second-)edge-to-receiver distance, `a` =
      component of source-receiver separation parallel to the barrier edge, `d` = direct
      source-receiver distance.
  - Eq(18): `Kmet = exp(-(1/2000)*sqrt(dss*dsr*d/(2*z)))` for `z > 0`; `Kmet = 1` for `z <= 0`. For
    lateral (vertical-edge) diffraction, `Kmet = 1` always.
- Barrier attenuation `Dz` capped: <= 20 dB for single diffraction (thin barriers), <= 25 dB for
  double diffraction (thick barriers). For >2 barriers, use eq.14 with the two most effective,
  ignore the rest.

## 7.5 Reflections (image sources)

Applies per octave band only when: a specular reflection path exists (fig. 8), reflection
coefficient rho > 0.2, and surface is large relative to wavelength:
`1/lambda > [2/(lmin*cos(beta))^2] * [ds,o * do,r / (ds,o + do,r)]` — Eq(19).

- Eq(20): `Lw,im = Lw + 10*lg(rho) + D_lr` dB — sound power level of the image source; rho = the
  reflection coefficient at incidence angle beta (Table 4: flat hard wall rho=1, building w/
  windows rho=0.8, factory wall 50% openings rho=0.4, open installations rho=0, cylinder — see
  eq. in Table 4/fig.9), D_lr = directivity index of the source toward the receiver image.
- Attenuation terms of eq.4 for the image source are computed along the reflected propagation
  path (source -> reflection point -> receiver).

## 8 Meteorological correction

- Eq(21): `Cmet = 0` if `dp <= 10*(hs+hr)`.
- Eq(22): `Cmet = C0*[1 - 10*(hs+hr)/dp]` if `dp > 10*(hs+hr)` (verified against page image).
  - `C0` (dB) depends on local meteorological statistics (wind speed/direction, temp. gradients);
    practice range 0-5 dB, values >2 dB exceptional (Note 22). Read from a fig. 10 curve family in
    practice (Cmet/C0 vs. dp for various hs+hr) — not transcribed, minor/secondary term.

## Table 5 — estimated accuracy of L_AT(DW), eqs (1)-(10)

| mean height h of source+receiver | 0 < d < 100 m | 100 m < d < 1000 m |
|---|---|---|
| 0 < h < 5 m | ±3 dB | ±3 dB |
| 5 m < h < 30 m | ±1 dB | ±3 dB |

No accuracy estimate given for d > 1000 m. Estimates exclude screening/reflection effects and
apply to downwind conditions only (case a in clause 9); case b (long-term average, eq. 6/21/22)
has no stated accuracy table.

## Annex A (informative) — Amisc contributions

- **Foliage (Afol)**: only counts if dense enough to fully block line of sight. Table A.1:
  10-20 m path through dense foliage -> flat dB values per band (63Hz:0 ... 8000Hz:3 dB);
  20-200 m -> dB/m rates per band (63Hz:0.02 ... 8000Hz:0.12 dB/m); path > 200 m -> use the 200 m
  value. Path may bend at 15° to the ground into/out of the foliage (fig. A.1).
- **Industrial sites (Asite)**: linear with path length through installations, capped at 10 dB;
  Table A.2 gives dB/m per band (63Hz:0 ... 8000Hz:0.015 dB/m); recommend measuring directly if
  possible.
- **Housing (Ahaus)**: capped at 10 dB. Eq(A.1): `Ahaus = Ahaus,1 + Ahaus,2`.
  - Eq(A.2): `Ahaus,1 = 0.1*B*db` dB — B = building plan-area density (0-1), db = path length
    through the built-up region.
  - Eq(A.3): `Ahaus,2 = -10*lg(1 - p/100)` dB — p = % of road/rail frontage lined by building
    facades (<=90%), only for well-defined rows of buildings near a corridor.
  - Interaction with Agr: if propagating through housing, Agr is normally taken as 0; but if the
    no-houses ground attenuation Agr,0 would exceed Ahaus, use Agr,0 instead and ignore Ahaus.

Table 4's cylinder-reflection formula (verified): `rho = D*sin(phi/2) / (2*dsc)`, valid only when
`dsc << dcr` (D = cylinder diameter, dsc = source-to-cylinder-centre distance, phi = supplement of
angle SC-CR). Only the fig.10 `Cmet/C0` vs. `dp` curve family (a graphical read, not a closed-form
equation beyond eq.22 above) remains untranscribed — low priority.
