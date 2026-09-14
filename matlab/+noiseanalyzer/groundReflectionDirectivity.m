function Domega = groundReflectionDirectivity(hs, hr, dp)
%GROUNDREFLECTIONDIRECTIVITY Directivity correction term D_omega, ISO 9613-2:1996 eq.(11) —
%   required as part of Dc in eq.(3) whenever ground attenuation is computed via the simplified
%   groundAttenuationSimplified (eq.10) method, to account for the apparent increase in source
%   sound power due to reflections from the ground near the source.
arguments
    hs (1,1) double
    hr (1,1) double
    dp (1,1) double
end
Domega = 10*log10(1 + (dp^2 + (hs-hr)^2)/(dp^2 + (hs+hr)^2));
end
