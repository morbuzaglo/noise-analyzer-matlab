function Acurv = cylindricalReflectionAttenuation(dS, dR, r, d)
%CYLINDRICALREFLECTIONATTENUATION Additional attenuation from reflection off a cylindrical
%   surface (tanks, silos, curved facades) instead of a flat one, ISO 9613-2:2024 eq.(30)
%   (7.5.4): Acurv = 10*lg[1 + (2*dS*dR)/(r*(dS+dR)) * (1-k^2)^(-1/2)] dB, k = d/r.
%   dS/dR = source/receiver-to-reflection-point distances (m); r = cylinder radius (m); d =
%   perpendicular distance from the cylinder's centre to the incident ray's line (m), all
%   measured in projection parallel to the cylinder axis. Valid for lambda << r. Applied as part
%   of Amisc; use with imageSourceLevel for the reflected-path power level (absorption of the
%   cylinder surface at the reflection point per 7.5.2).
arguments
    dS (1,1) double
    dR (1,1) double
    r (1,1) double
    d (1,1) double
end
k = d/r;
Acurv = 10*log10(1 + (2*dS*dR)/(r*(dS+dR)) * (1-k^2)^(-1/2));
end
