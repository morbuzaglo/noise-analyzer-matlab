function Agr = groundAttenuation(freqHz, Gs, Gr, Gm, hs, hr, dp)
%GROUNDATTENUATION Ground attenuation Agr per octave band, ISO 9613-2:2024 eqs.(11)-(13) & Table 3
%   (general method). Ground factor G: hard=0, porous=1, mixed=fraction porous, given separately
%   for the source (Gs), receiver (Gr) and middle (Gm) regions.
%
%   Table 3 (the As/Ar/Am per-band expressions) is unchanged from ISO 9613-2:1996, but the 2024
%   edition changed how they combine: instead of the 1996 plain sum (Agr = As+Ar+Am, eq.9), 2024
%   uses a non-linear combination with a geometric correction Kgeo (see groundGeometryFactor),
%   eq.(11): Agr = -10*lg[1 + (10^(-A'gr/10) - 1)*Kgeo], A'gr = As+Ar+Am (eq.12). Per the
%   standard's own note, this "accounts for the vanishing ground influence if dp < hs and/or
%   dp < hr" -- a case the 1996 plain sum handled less accurately. Reduces exactly to the 1996
%   formula when Kgeo=1 (large dp relative to heights): -10*lg[10^(-A'gr/10)] = A'gr.
%
%   Note: q (Table 3 note 2) is 0 whenever dp <= 30*(hs+hr) — which is exactly the standard's own
%   "no middle region" condition (7.3.1) — so Am correctly comes out to 0 in that case without
%   needing a separate branch.
arguments
    freqHz double
    Gs (1,1) double
    Gr (1,1) double
    Gm (1,1) double
    hs (1,1) double
    hr (1,1) double
    dp (1,1) double
end
As = arrayfun(@(f) noiseanalyzer.groundAttenuationSourceOrReceiverTerm(f, Gs, hs, dp), freqHz);
Ar = arrayfun(@(f) noiseanalyzer.groundAttenuationSourceOrReceiverTerm(f, Gr, hr, dp), freqHz);

if dp <= 30*(hs + hr)
    q = 0;
else
    q = 1 - 30*(hs + hr)/dp;
end
Am = arrayfun(@(f) middleTerm(f, Gm, q), freqHz);

AgrPrime = As + Ar + Am;
Kgeo = noiseanalyzer.groundGeometryFactor(dp, hs, hr);
Agr = -10*log10(1 + (10.^(-AgrPrime/10) - 1) * Kgeo);
end

function Am = middleTerm(f, Gm, q)
if f == 63
    Am = -3*q;
else
    Am = -3*q*(1 - Gm);
end
end
