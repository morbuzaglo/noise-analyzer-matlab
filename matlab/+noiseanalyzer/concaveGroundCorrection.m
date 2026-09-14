function dAgr = concaveGroundCorrection(hm, hs, hr)
%CONCAVEGROUNDCORRECTION Additional ground-attenuation correction for concave (valley) terrain,
%   ISO 9613-2:2024 Annex D.5 eq.(D.1)-(D.2): dAgr = -3 dB, added to Agr in all octave bands, when
%   the mean propagation height hm is at least 50% higher than it would be over flat ground:
%   hm >= 1.5*(hs+hr)/2. The standard flags this itself as a "temporary convention," indicative
%   only, to be judged case by case. Returns 0 when the condition isn't met.
arguments
    hm (1,1) double
    hs (1,1) double
    hr (1,1) double
end
if hm >= 1.5*(hs + hr)/2
    dAgr = -3;
else
    dAgr = 0;
end
end
