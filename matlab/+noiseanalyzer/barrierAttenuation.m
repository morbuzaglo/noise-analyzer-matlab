function Abar = barrierAttenuation(freqHz, dss, dsr, a, d, e, Agr, C2)
%BARRIERATTENUATION Barrier (screening) insertion loss, ISO 9613-2:1996 eqs.(12)-(18).
%
%   For diffraction over the top edge (downwind), pass the ground attenuation Agr that would
%   apply with the barrier absent (see groundAttenuation) and this returns Abar = Dz - Agr per
%   eq.(12), capped at >= 0. For diffraction around a vertical edge (lateral), pass Agr = 0 (the
%   default) to get Abar = Dz per eq.(13).
%
%   e = 0 (default) selects single diffraction (one edge, C3 = 1 per the standard's special
%   case); e > 0 selects double diffraction (two edges separated by e, eq.15/17). dss, dsr, a, d,
%   e are geometry and do not depend on octave band; freqHz may be a vector of bands.
arguments
    freqHz double
    dss (1,1) double
    dsr (1,1) double
    a (1,1) double
    d (1,1) double
    e (1,1) double = 0
    Agr double = 0
    C2 (1,1) double = 20
end
if e == 0
    z = sqrt((dss + dsr)^2 + a^2) - d;
else
    z = sqrt((dss + dsr + e)^2 + a^2) - d;
end

if z > 0
    Kmet = exp(-(1/2000) * sqrt(dss*dsr*d / (2*z)));
else
    Kmet = 1;
end

lambda = 340 ./ freqHz;
if e == 0
    C3 = 1;
else
    C3 = (1 + (5*lambda./e).^2) ./ (1/3 + (5*lambda./e).^2);
end

Dz = 10*log10(3 + (C2./lambda).*C3.*z.*Kmet);

if e > 0
    capDb = 25; % double diffraction (thick barriers)
else
    capDb = 20; % single diffraction (thin barriers)
end
Dz = min(Dz, capDb);

Abar = max(Dz - Agr, 0);
end
