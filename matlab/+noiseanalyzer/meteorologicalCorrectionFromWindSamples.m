function C0 = meteorologicalCorrectionFromWindSamples(phiM, windDirectionSamples, Q, phiWidth)
%METEOROLOGICALCORRECTIONFROMWINDSAMPLES Derive C0 (for use in meteorologicalCorrection, eq.31/32)
%   directly from a set of raw wind-direction observations, ISO 9613-2:2024 Annex C.1 eq.(C.6) --
%   avoids needing a pre-binned wind rose:
%   C0(phiM) = -10*lg{ (1/N) * sum_n[ 10^(0.1*Dwd(phi_n - phiM)) ] } dB.
%   phiM = source-to-receiver propagation direction (rad, meteorological convention: 0=north,
%   clockwise-positive); windDirectionSamples = vector of recorded wind directions (rad, same
%   convention) for every sample in the reference/long-term interval of interest (e.g. all hourly
%   readings for the season/year being assessed); Q/phiWidth passed through to windDirectivityDwd.
arguments
    phiM (1,1) double
    windDirectionSamples (1,:) double
    Q (1,1) double = 5
    phiWidth (1,1) double = pi/4
end
Dwd = noiseanalyzer.windDirectivityDwd(windDirectionSamples - phiM, Q, phiWidth);
C0 = -10*log10(mean(10.^(0.1*Dwd)));
end
