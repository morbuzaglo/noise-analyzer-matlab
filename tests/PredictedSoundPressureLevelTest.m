classdef PredictedSoundPressureLevelTest < matlab.unittest.TestCase
%PREDICTEDSOUNDPRESSURELEVELTEST predictedSoundPressureLevel against the project's own already-
%   verified worked example (README/CLAUDE.md: 100 m, hs=4, hr=1.5, hard ground, 20 C/70% RH ->
%   LAT(DW) = 57.34 dB, ISO 9613-2:2024) plus basic physical sanity checks.

    methods (Test)
        function matchesReadmeWorkedExample(testCase)
            bands = noiseanalyzer.iso9613OctaveBands();
            Lw = 100 * ones(1, numel(bands));
            [LpA, ~, ~] = noiseanalyzer.predictedSoundPressureLevel(Lw, 100, ...
                'Freq', bands, 'TemperatureC', 20, 'RelativeHumidityPct', 70, ...
                'Gs', 0, 'Gr', 0, 'Gm', 0, 'hs', 4, 'hr', 1.5);
            testCase.verifyEqual(LpA, 57.34, 'AbsTol', 0.05);
        end

        function scalarLwIsBroadcastFlat(testCase)
            bands = noiseanalyzer.iso9613OctaveBands();
            [LpA1, Lp1] = noiseanalyzer.predictedSoundPressureLevel(90, 50, 'Freq', bands);
            [LpA2, Lp2] = noiseanalyzer.predictedSoundPressureLevel(90*ones(1,numel(bands)), 50, 'Freq', bands);
            testCase.verifyEqual(LpA1, LpA2, 'AbsTol', 1e-10);
            testCase.verifyEqual(Lp1, Lp2, 'AbsTol', 1e-10);
        end

        function levelDecreasesMonotonicallyWithDistance(testCase)
            distances = [10 20 40 80 160];
            levels = arrayfun(@(d) noiseanalyzer.predictedSoundPressureLevel(100, d), distances);
            testCase.verifyTrue(all(diff(levels) < 0));
        end

        function simplifiedGroundRequiresGroundHeightMean(testCase)
            testCase.verifyError(@() noiseanalyzer.predictedSoundPressureLevel(100, 50, ...
                'UseSimplifiedGround', true), ...
                'noiseanalyzer:predictedSoundPressureLevel:MissingGroundHeightMean');
        end

        function simplifiedAndGeneralGroundAreReasonablyConsistent(testCase)
            [LpAGeneral, ~, terms] = noiseanalyzer.predictedSoundPressureLevel(100, 100, ...
                'Gs', 1, 'Gr', 1, 'Gm', 1, 'hs', 2, 'hr', 2);
            hm = mean([2 2]); % simple flat-terrain mean path height for this geometry
            [LpASimplified] = noiseanalyzer.predictedSoundPressureLevel(100, 100, ...
                'UseSimplifiedGround', true, 'GroundHeightMean', hm);
            testCase.verifyEqual(LpAGeneral, LpASimplified, 'AbsTol', 5);
            testCase.verifyGreaterThan(terms.Adiv, 0);
        end
    end
end
