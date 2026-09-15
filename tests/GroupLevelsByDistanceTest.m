classdef GroupLevelsByDistanceTest < matlab.unittest.TestCase
%GROUPLEVELSBYDISTANCETEST Tolerance-based distance grouping and per-group aggregation.

    methods (Test)
        function groupsWithinTolerance(testCase)
            distances = [10; 10.2; 20; 20.1; 5];
            levels = [70; 71; 60; 61; 80];
            [uniqueD, agg, idx] = noiseanalyzer.groupLevelsByDistance(distances, levels, "mean", 0.5);

            testCase.verifyEqual(numel(uniqueD), 3);
            testCase.verifyEqual(uniqueD, [5; 10.1; 20.05], 'AbsTol', 1e-10);
            testCase.verifyEqual(idx(1), idx(2)); % the two ~10 m mics share a group
            testCase.verifyEqual(idx(3), idx(4)); % the two ~20 m mics share a group
            testCase.verifyNotEqual(idx(1), idx(3));
            testCase.verifyEqual(agg(uniqueD == 5), 80, 'AbsTol', 1e-10);
        end

        function distinctDistancesStayUngrouped(testCase)
            distances = [1; 2; 3];
            levels = [90; 80; 70];
            [uniqueD, agg] = noiseanalyzer.groupLevelsByDistance(distances, levels, "max", 0.1);
            testCase.verifyEqual(numel(uniqueD), 3);
            testCase.verifyEqual(agg, levels(:));
        end

        function maxAggregationWithinGroup(testCase)
            distances = [10; 10; 10];
            levels = [50; 65; 55];
            [~, agg] = noiseanalyzer.groupLevelsByDistance(distances, levels, "max");
            testCase.verifyEqual(agg, 65);
        end

        function sizeMismatchErrors(testCase)
            testCase.verifyError(@() noiseanalyzer.groupLevelsByDistance([1;2], [1;2;3]), ...
                'noiseanalyzer:groupLevelsByDistance:SizeMismatch');
        end
    end
end
