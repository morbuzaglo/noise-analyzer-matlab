classdef FitSourceLevelAndGroundFactorTest < matlab.unittest.TestCase
%FITSOURCELEVELANDGROUNDFACTORTEST End-to-end validation: fit recovers known Lw/G from synthetic,
%   noise-free multi-mic data (the case that matters most: this is what proves the optimizer
%   actually works, since no real experimental dataset exists yet).

    methods (Test)
        function recoversKnownParametersNoiseFree(testCase)
            trueLw = 105;
            trueG = 0.7;
            distances = [10; 20; 40; 80; 160];
            [~, measured] = noiseanalyzer.simulateMultiMicMeasurement(trueLw, distances, ...
                'Gs', trueG, 'Gr', trueG, 'Gm', trueG);

            fitResult = noiseanalyzer.fitSourceLevelAndGroundFactor(distances, measured);

            testCase.verifyEqual(fitResult.LwFit, trueLw, 'AbsTol', 0.5);
            testCase.verifyEqual(fitResult.GFit, trueG, 'AbsTol', 0.05);
            testCase.verifyLessThan(fitResult.RMSE, 0.1);
        end

        function recoversKnownParametersWithFminsearchFallback(testCase)
            trueLw = 90;
            trueG = 0.3;
            distances = [15; 30; 60; 120];
            [~, measured] = noiseanalyzer.simulateMultiMicMeasurement(trueLw, distances, ...
                'Gs', trueG, 'Gr', trueG, 'Gm', trueG);

            fitResult = noiseanalyzer.fitSourceLevelAndGroundFactor(distances, measured, ...
                'Solver', 'fminsearch');

            testCase.verifyEqual(fitResult.LwFit, trueLw, 'AbsTol', 0.5);
            testCase.verifyEqual(fitResult.GFit, trueG, 'AbsTol', 0.05);
        end

        function fixedGroundFactorFitsLwOnly(testCase)
            trueLw = 100;
            fixedG = 0.5;
            distances = [10; 40; 100];
            [~, measured] = noiseanalyzer.simulateMultiMicMeasurement(trueLw, distances, ...
                'Gs', fixedG, 'Gr', fixedG, 'Gm', fixedG);

            fitResult = noiseanalyzer.fitSourceLevelAndGroundFactor(distances, measured, ...
                'FitTargets', "Lw", 'FixedG', fixedG);

            testCase.verifyEqual(fitResult.LwFit, trueLw, 'AbsTol', 0.2);
            testCase.verifyEqual(fitResult.GFit, fixedG); % held fixed, not fit
        end

        function tooFewDistancesErrors(testCase)
            testCase.verifyError(@() noiseanalyzer.fitSourceLevelAndGroundFactor(10, 60), ...
                'noiseanalyzer:fitSourceLevelAndGroundFactor:TooFewDistances');
        end

        function globalOptimizationSolversRecoverParameters(testCase)
            testCase.assumeTrue(~isempty(which('particleswarm')), ...
                'Global Optimization Toolbox (particleswarm) not available on this machine.');
            trueLw = 95; trueG = 0.6;
            distances = [10; 25; 50; 100];
            [~, measured] = noiseanalyzer.simulateMultiMicMeasurement(trueLw, distances, ...
                'Gs', trueG, 'Gr', trueG, 'Gm', trueG);
            fitResult = noiseanalyzer.fitSourceLevelAndGroundFactor(distances, measured, ...
                'Solver', 'particleswarm');
            testCase.verifyEqual(fitResult.LwFit, trueLw, 'AbsTol', 1);
            testCase.verifyEqual(fitResult.GFit, trueG, 'AbsTol', 0.1);
        end
    end
end
