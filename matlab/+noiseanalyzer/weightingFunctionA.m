function A = weightingFunctionA(f)
%WEIGHTINGFUNCTIONA Analytical A-frequency-weighting curve in dB, IEC 61672-1:2013 Annex E eq E.6.
%   Pole frequencies (E.4.1) and normalization constant A_1000 (E.4.2) per the standard.
%   Formula structure ported from acoustics.standards.iec_61672_1_2013 (python-acoustics,
%   BSD-3-Clause, https://github.com/python-acoustics/python-acoustics).
arguments
    f double
end
f1 = 20.60; f2 = 107.7; f3 = 737.9; f4 = 12194.0;
A1000 = -2.000; % dB

num = f4^2 .* f.^4;
den = (f.^2 + f1^2) .* sqrt(f.^2 + f2^2) .* sqrt(f.^2 + f3^2) .* (f.^2 + f4^2);
A = 20*log10(num ./ den) - A1000;
end
