function [t, Lp] = timeWeightedLevel(p, fs, timeConstant, p0)
%TIMEWEIGHTEDLEVEL Continuous exponential time-weighted sound pressure level, IEC 61672-1:2013.
%   Exponential time-weighting is defined by the standard as a one-pole low-pass of p^2 with
%   unity DC gain and time constant tau: H(s) = 1/(tau*s + 1), pole at s = -1/tau, bilinear-
%   transformed to digital. Returns one value per input sample.
%
%   Note: this is a from-the-standard reimplementation, not a port of
%   acoustics.standards.iec_61672_1_2013.integrate (python-acoustics) — that function's analog
%   prototype (`zpk2tf([1.0], [1.0, integration_time], [1.0])`) does not reduce to a pole at
%   -1/tau with unity DC gain as its own docstring claims, so it was not used as a reference here.
arguments
    p (:,1) double
    fs (1,1) double
    timeConstant (1,1) double = noiseanalyzer.timeWeightingConstants("FAST")
    p0 (1,1) double = noiseanalyzer.referencePressure()
end
[b, a] = noiseanalyzer.bilinearTransform([1], [timeConstant, 1], fs);
meanSquare = filter(b, a, p.^2);
meanSquare = max(meanSquare, eps); % guard log10(0) at signal start
Lp = 10*log10(meanSquare ./ p0^2);
t = (0:numel(Lp)-1)' ./ fs;
end
