classdef SimulateMultiMicMeasurementTest < matlab.unittest.TestCase
%SIMULATEMULTIMICMEASUREMENTTEST Noise-free simulateMultiMicMeasurement matches
%   predictedSoundPressureLevel exactly (it's a thin wrapper); noise injection behaves as
%   expected.

    methods (Test)
        function noiseFreeMatchesForwardModel(testCase)
            distances = [10; 30; 60; 100];
            trueLw = 95;
            [d, levels] = noiseanalyzer.simulateMultiMicMeasurement(trueLw, distances, ...
                'Gs', 0.3, 'Gr', 0.3, 'Gm', 0.3);
            expected = arrayfun(@(dd) noiseanalyzer.predictedSoundPressureLevel(trueLw, dd, ...
                'Gs', 0.3, 'Gr', 0.3, 'Gm', 0.3), distances);
            testCase.verifyEqual(d, distances);
            testCase.verifyEqual(levels, expected, 'AbsTol', 1e-10);
        end

        function noiseIsReproducibleWithSeed(testCase)
            distances = [10; 30; 60];
            [~, levels1] = noiseanalyzer.simulateMultiMicMeasurement(95, distances, ...
                'NoiseStdDb', 2, 'Seed', 42);
            [~, levels2] = noiseanalyzer.simulateMultiMicMeasurement(95, distances, ...
                'NoiseStdDb', 2, 'Seed', 42);
            testCase.verifyEqual(levels1, levels2);
        end

        function truthStructEchoesInputs(testCase)
            [~, ~, truth] = noiseanalyzer.simulateMultiMicMeasurement(88, [10;20], 'Gs', 0.7);
            testCase.verifyEqual(truth.LwOctave, 88);
            testCase.verifyEqual(truth.Gs, 0.7);
        end
    end
end
