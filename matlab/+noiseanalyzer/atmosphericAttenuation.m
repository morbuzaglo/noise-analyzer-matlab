function Aatm = atmosphericAttenuation(alpha, d)
%ATMOSPHERICATTENUATION Attenuation due to atmospheric absorption, ISO 9613-2:2024 eq.(9)
%   (= ISO 9613-2:1996 eq.(8), unchanged, renumbered because 2024 inserted extra equations
%   earlier in the clause): Aatm = alpha*d/1000 dB, alpha = atmosphericAttenuationCoefficient(...)
%   in dB/km, d in metres.
arguments
    alpha double
    d double
end
Aatm = alpha .* d ./ 1000;
end
