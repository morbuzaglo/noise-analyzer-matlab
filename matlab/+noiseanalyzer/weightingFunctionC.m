function C = weightingFunctionC(f)
%WEIGHTINGFUNCTIONC Analytical C-frequency-weighting curve in dB, IEC 61672-1:2013 Annex E eq E.1.
%   Pole frequencies (E.4.1) and normalization constant C_1000 (E.4.2) per the standard.
%   Formula structure ported from acoustics.standards.iec_61672_1_2013 (python-acoustics,
%   BSD-3-Clause, https://github.com/python-acoustics/python-acoustics).
arguments
    f double
end
f1 = 20.60; f4 = 12194.0;
C1000 = -0.062; % dB

num = f4^2 .* f.^2;
den = (f.^2 + f1^2) .* (f.^2 + f4^2);
C = 20*log10(num ./ den) - C1000;
end
