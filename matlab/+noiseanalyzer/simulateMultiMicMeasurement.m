function [distances, simulatedLevelsDbA, truth] = simulateMultiMicMeasurement(trueLwOctave, distances, opts)
%SIMULATEMULTIMICMEASUREMENT Synthetic multi-microphone measurement generator: computes the
%   ISO 9613-2 predicted level (predictedSoundPressureLevel) at each requested distance for a
%   known ("true") source power level and propagation conditions, optionally adding measurement
%   noise. Used to build validation datasets with known ground truth (no real experiment data
%   required) for testing invertSourcePowerLevel/fitSourceLevelAndGroundFactor.
%
%   opts mirrors predictedSoundPressureLevel's Name-Value options, plus opts.NoiseStdDb for
%   additive Gaussian measurement noise (dB, default 0 = noise-free) and opts.Seed to make the
%   noise reproducible.
%
%   truth - struct echoing the ground-truth parameters used to generate the data (LwOctave, and
%   every opts field relevant to the fit), for convenient comparison against a later fit result.
arguments
    trueLwOctave (1,:) double
    distances (:,1) double
    opts.Freq (1,:) double = noiseanalyzer.iso9613OctaveBands()
    opts.TemperatureC (1,1) double = 15
    opts.RelativeHumidityPct (1,1) double = 70
    opts.PressureKPa (1,1) double = 101.325
    opts.Gs (1,1) double = 0.5
    opts.Gr (1,1) double = 0.5
    opts.Gm (1,1) double = 0.5
    opts.hs (1,1) double = 1.5
    opts.hr (1,1) double = 1.5
    opts.Dc (1,1) double = 0
    opts.Abar (1,1) double = 0
    opts.Amisc (1,1) double = 0
    opts.C0 (1,1) double = 0
    opts.UseSimplifiedGround (1,1) logical = false
    opts.GroundHeightMean (1,1) double = NaN
    opts.NoiseStdDb (1,1) double = 0
    opts.Seed double = []
end
n = numel(distances);
simulatedLevelsDbA = zeros(n, 1);

forwardArgs = namedargs2cell(rmfield(opts, {'NoiseStdDb', 'Seed'}));
for i = 1:n
    simulatedLevelsDbA(i) = noiseanalyzer.predictedSoundPressureLevel(trueLwOctave, distances(i), forwardArgs{:});
end

if opts.NoiseStdDb > 0
    if ~isempty(opts.Seed)
        rngState = rng();
        rng(opts.Seed);
    end
    simulatedLevelsDbA = simulatedLevelsDbA + opts.NoiseStdDb * randn(n, 1);
    if ~isempty(opts.Seed)
        rng(rngState);
    end
end

truth = opts;
truth.LwOctave = trueLwOctave;
end
