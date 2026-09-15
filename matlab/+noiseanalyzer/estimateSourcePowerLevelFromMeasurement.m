function LwOverall = estimateSourcePowerLevelFromMeasurement(LpA_measured, spectrumShapeDb, Dc, Adiv, Aatm, Agr, Abar, Amisc, freqHz)
%ESTIMATESOURCEPOWERLEVELFROMMEASUREMENT Overall (A-weighted) source sound power level implied by
%   a single measured overall SPL, given an assumed relative octave-band spectrum shape.
%
%   Most measurements from this app are a single overall dB(A) value (LAeq), not a calibrated
%   per-band spectrum, so invertSourcePowerLevel (which needs a real per-band Lp) can't be applied
%   directly. Instead, assume the source's octave-band power spectrum has a known relative SHAPE
%   spectrumShapeDb (dB, relative -- an offset added to the unknown overall level; default flat,
%   i.e. all bands equal), so that Lw(band) = LwOverall + spectrumShapeDb(band). Because
%   aWeightedSoundPressureLevel is a log-sum-exp, this is separable:
%
%       LpA_predicted(LwOverall) = LwOverall + transferLevel
%       transferLevel = aWeightedSoundPressureLevel(pointSourceOctaveBandLevel(spectrumShapeDb, ...))
%
%   so LwOverall = LpA_measured - transferLevel exactly (no optimization needed) for this shape
%   assumption. Adiv/Aatm/Agr/Abar/Amisc follow pointSourceOctaveBandLevel's broadcasting rules
%   (scalar or per-band).
arguments
    LpA_measured (1,1) double
    spectrumShapeDb (1,:) double = zeros(1, numel(noiseanalyzer.iso9613OctaveBands()))
    Dc double = 0
    Adiv double = 0
    Aatm double = 0
    Agr double = 0
    Abar double = 0
    Amisc double = 0
    freqHz (1,:) double = noiseanalyzer.iso9613OctaveBands()
end
LpShape = noiseanalyzer.pointSourceOctaveBandLevel(spectrumShapeDb, Dc, Adiv, Aatm, Agr, Abar, Amisc);
transferLevel = noiseanalyzer.aWeightedSoundPressureLevel(LpShape, freqHz);
LwOverall = LpA_measured - transferLevel;
end
