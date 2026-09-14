function LAT = aWeightedSoundPressureLevel(Lp, freqHz)
%AWEIGHTEDSOUNDPRESSURELEVEL Combine per-contribution, per-octave-band SPLs into the overall
%   downwind A-weighted level, ISO 9613-2:1996 eq.(5): L_AT(DW) = 10*lg{ sum_i sum_j
%   10^(0.1*[Lp(i,j) + Af(j)]) }.
%   Lp: matrix, one row per contribution i (source and/or propagation path), one column per
%   octave band j (freqHz, matching noiseanalyzer.iso9613OctaveBands() by default). Af is the
%   standard A-weighting (IEC 61672-1's analytical form — same basis as the IEC 651 A-weighting
%   the standard cites).
arguments
    Lp double
    freqHz (1,:) double = noiseanalyzer.iso9613OctaveBands()
end
Af = noiseanalyzer.weightingFunctionA(freqHz);
LAT = 10*log10(sum(10.^(0.1*(Lp + Af)), 'all'));
end
