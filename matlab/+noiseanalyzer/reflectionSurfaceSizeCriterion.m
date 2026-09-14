function valid = reflectionSurfaceSizeCriterion(freqHz, leff, dSO, dOR)
%REFLECTIONSURFACESIZECRITERION Whether a reflecting surface is large enough, relative to
%   wavelength, for a specular reflection to be counted in a given octave band, ISO 9613-2:2024
%   eq.(26): 1/lambda > [2/leff^2] * [dS,O*dO,R / (dS,O+dO,R)].
%   leff from reflectionEffectiveLength (eq.27); dSO/dOR = source-to-reflection-point and
%   reflection-point-to-receiver distances (possibly bent, for multi-reflection paths), m.
%   If false for a band, that band's reflection contribution should be neglected.
arguments
    freqHz double
    leff (1,1) double
    dSO (1,1) double
    dOR (1,1) double
end
lambda = 340 ./ freqHz;
valid = (1./lambda) > (2/leff^2) * (dSO*dOR/(dSO+dOR));
end
