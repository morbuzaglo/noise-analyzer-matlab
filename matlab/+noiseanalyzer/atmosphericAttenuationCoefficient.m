function alpha = atmosphericAttenuationCoefficient(f, temperatureCelsius, relativeHumidityPercent, pressureKPa)
%ATMOSPHERICATTENUATIONCOEFFICIENT Atmospheric attenuation coefficient alpha (dB/km) per
%   ISO 9613-1:1993 (the analytical formula behind ISO 9613-2:1996 Table 2 / eq.8). Valid for
%   10-30 degC, per the standard's stated range of applicability.
%   Ported from acoustics.standards.iso_9613_1_1993 (python-acoustics, BSD-3-Clause).
%
%   Note: relativeHumidityPercent is used as a bare number (e.g. 70, not 0.70) — this matches
%   the standard's own formula convention, verified by reproducing ISO 9613-2 Table 2 exactly
%   (see smoke test).
arguments
    f double                          % frequency, Hz
    temperatureCelsius (1,1) double
    relativeHumidityPercent (1,1) double
    pressureKPa (1,1) double = 101.325
end
T = temperatureCelsius + 273.15;
T0 = 293.15;      % reference temperature, K
T01 = 273.16;     % triple-point temperature of water, K
pr = 101.325;     % reference pressure, kPa

psat = pr * 10^(-6.8346*(T01/T)^1.261 + 4.6151);
h = relativeHumidityPercent * psat / pressureKPa;

frO = (pressureKPa/pr) * (24 + 4.04e4*h*(0.02+h)/(0.391+h));
frN = (pressureKPa/pr) * (T/T0)^(-0.5) * (9 + 280*h*exp(-4.170*((T/T0)^(-1/3) - 1)));

alphaPerMetre = 8.686 .* f.^2 .* ( ...
    1.84e-11 * (pr/pressureKPa) * (T/T0)^0.5 + ...
    (T/T0)^(-2.5) * ( ...
        0.01275*exp(-2239.1/T) .* (frO + f.^2./frO).^(-1) + ...
        0.1068*exp(-3352.0/T)  .* (frN + f.^2./frN).^(-1) ...
    ) ...
);
alpha = alphaPerMetre * 1000; % dB/m -> dB/km
end
