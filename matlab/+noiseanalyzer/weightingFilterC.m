function [b, a] = weightingFilterC(fs)
%WEIGHTINGFILTERC Digital C-weighting filter coefficients via bilinear transform of the
%   analog pole model in IEC 61672-1:2013 Annex E eq E.1. Ported from
%   acoustics.standards.iec_61672_1_2013.weighting_system_c (python-acoustics, BSD-3-Clause).
arguments
    fs (1,1) double
end
f1 = 20.60; f4 = 12194.0;
C1000 = -0.062;

num = [(2*pi*f4)^2 * 10^(-C1000/20), 0, 0];
part1 = [1, 4*pi*f4, (2*pi*f4)^2];
part2 = [1, 4*pi*f1, (2*pi*f1)^2];
den = conv(part1, part2);

[b, a] = noiseanalyzer.bilinearTransform(num, den, fs);
end
