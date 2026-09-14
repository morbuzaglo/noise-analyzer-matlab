function Domega = groundReflectionDirectivity(hs, hr, dp)
%GROUNDREFLECTIONDIRECTIVITY Directivity correction term D_omega, ISO 9613-2:2024 eq.(15):
%   D_omega = 10*lg(1 + Kgeo) — required as part of Dc in eq.(3) whenever ground attenuation is
%   computed via the simplified groundAttenuationSimplified (eq.14) method, to account for the
%   apparent increase in source sound power due to reflections from the ground near the source.
%   Algebraically identical to the ISO 9613-2:1996 eq.(11) form
%   (10*lg{1+[dp^2+(hs-hr)^2]/[dp^2+(hs+hr)^2]}) — 2024 just refactored it to share Kgeo with
%   groundAttenuation; not a substantive change.
arguments
    hs (1,1) double
    hr (1,1) double
    dp (1,1) double
end
Kgeo = noiseanalyzer.groundGeometryFactor(dp, hs, hr);
Domega = 10*log10(1 + Kgeo);
end
