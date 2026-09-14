function Kgeo = groundGeometryFactor(dp, hs, hr)
%GROUNDGEOMETRYFACTOR Geometric correction factor Kgeo, ISO 9613-2:2024 eq.(13):
%   Kgeo = [dp^2 + (hs-hr)^2] / [dp^2 + (hs+hr)^2]. New in the 2024 edition -- feeds both the
%   general-method ground attenuation (groundAttenuation) and the ground-reflection directivity
%   term (groundReflectionDirectivity).
arguments
    dp (1,1) double
    hs (1,1) double
    hr (1,1) double
end
Kgeo = (dp^2 + (hs-hr)^2) / (dp^2 + (hs+hr)^2);
end
