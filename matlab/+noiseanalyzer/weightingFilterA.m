function [b, a] = weightingFilterA(fs)
%WEIGHTINGFILTERA Digital A-weighting filter coefficients via bilinear transform of the
%   analog pole model in IEC 61672-1:2013 Annex E eq E.6. Ported from
%   acoustics.standards.iec_61672_1_2013.weighting_system_a (python-acoustics, BSD-3-Clause).
arguments
    fs (1,1) double
end
f1 = 20.60; f2 = 107.7; f3 = 737.9; f4 = 12194.0;
A1000 = -2.000;

num = [(2*pi*f4)^2 * 10^(-A1000/20), 0, 0, 0, 0];
part1 = [1, 4*pi*f4, (2*pi*f4)^2];
part2 = [1, 4*pi*f1, (2*pi*f1)^2];
part3 = [1, 2*pi*f3];
part4 = [1, 2*pi*f2];
den = conv(conv(conv(part1, part2), part3), part4);

[b, a] = noiseanalyzer.bilinearTransform(num, den, fs);
end
