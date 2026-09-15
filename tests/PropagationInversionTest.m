classdef PropagationInversionTest < matlab.unittest.TestCase
%PROPAGATIONINVERSIONTEST invertSourcePowerLevel / estimateSourcePowerLevelFromMeasurement round
%   trips and closed-form checks.

    methods (Test)
        function roundTripScalar(testCase)
            Lw = 95;
            Dc = 2; Adiv = 31; Aatm = 1.2; Agr = -3; Abar = 4; Amisc = 0.5;
            Lp = noiseanalyzer.pointSourceOctaveBandLevel(Lw, Dc, Adiv, Aatm, Agr, Abar, Amisc);
            LwBack = noiseanalyzer.invertSourcePowerLevel(Lp, Dc, Adiv, Aatm, Agr, Abar, Amisc);
            testCase.verifyEqual(LwBack, Lw, 'AbsTol', 1e-10);
        end

        function roundTripPerBand(testCase)
            bands = noiseanalyzer.iso9613OctaveBands();
            Lw = 70 + 5*sin(1:numel(bands));
            Adiv = noiseanalyzer.geometricalDivergence(50);
            alpha = noiseanalyzer.atmosphericAttenuationCoefficient(bands, 20, 70);
            Aatm = noiseanalyzer.atmosphericAttenuation(alpha, 50);
            Agr = noiseanalyzer.groundAttenuation(bands, 0.5, 0.5, 0.5, 2, 1.5, 50);
            Lp = noiseanalyzer.pointSourceOctaveBandLevel(Lw, 0, Adiv, Aatm, Agr);
            LwBack = noiseanalyzer.invertSourcePowerLevel(Lp, 0, Adiv, Aatm, Agr);
            testCase.verifyEqual(LwBack, Lw, 'AbsTol', 1e-8);
        end

        function estimateFromMeasurementMatchesClosedForm(testCase)
            bands = noiseanalyzer.iso9613OctaveBands();
            trueLwOverall = 100;
            shape = [-10 -5 0 2 3 2 -1 -6]; % arbitrary relative shape
            Adiv = noiseanalyzer.geometricalDivergence(80);
            alpha = noiseanalyzer.atmosphericAttenuationCoefficient(bands, 15, 70);
            Aatm = noiseanalyzer.atmosphericAttenuation(alpha, 80);
            Agr = noiseanalyzer.groundAttenuation(bands, 0.5, 0.5, 0.5, 1.5, 1.5, 80);

            LpTrue = noiseanalyzer.pointSourceOctaveBandLevel(trueLwOverall + shape, 0, Adiv, Aatm, Agr);
            LpAMeasured = noiseanalyzer.aWeightedSoundPressureLevel(LpTrue, bands);

            LwEstimate = noiseanalyzer.estimateSourcePowerLevelFromMeasurement( ...
                LpAMeasured, shape, 0, Adiv, Aatm, Agr, 0, 0, bands);
            testCase.verifyEqual(LwEstimate, trueLwOverall, 'AbsTol', 1e-8);
        end

        function estimateFromMeasurementDefaultsToFlatShape(testCase)
            bands = noiseanalyzer.iso9613OctaveBands();
            trueLwOverall = 90;
            Adiv = noiseanalyzer.geometricalDivergence(30);
            LpTrue = noiseanalyzer.pointSourceOctaveBandLevel(trueLwOverall*ones(1,numel(bands)), 0, Adiv);
            LpAMeasured = noiseanalyzer.aWeightedSoundPressureLevel(LpTrue, bands);

            LwEstimate = noiseanalyzer.estimateSourcePowerLevelFromMeasurement( ...
                LpAMeasured, zeros(1, numel(bands)), 0, Adiv);
            testCase.verifyEqual(LwEstimate, trueLwOverall, 'AbsTol', 1e-8);
        end
    end
end
