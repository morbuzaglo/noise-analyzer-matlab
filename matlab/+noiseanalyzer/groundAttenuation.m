function Agr = groundAttenuation(freqHz, Gs, Gr, Gm, hs, hr, dp)
%GROUNDATTENUATION Ground attenuation Agr per octave band, ISO 9613-2:1996 eq.(9) / Table 3
%   (general method): Agr = As + Ar + Am. Ground factor G: hard=0, porous=1, mixed=fraction
%   porous, given separately for the source (Gs), receiver (Gr) and middle (Gm) regions.
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

Agr = As + Ar + Am;
end

function Am = middleTerm(f, Gm, q)
if f == 63
    Am = -3*q;
else
    Am = -3*q*(1 - Gm);
end
end
