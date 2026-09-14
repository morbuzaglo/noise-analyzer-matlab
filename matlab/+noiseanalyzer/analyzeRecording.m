function results = analyzeRecording(p, fs, referencePressure)
%ANALYZERECORDING Compute standard sound-level metrics from a raw pressure recording, using the
%   IEC 61672-1 functions in this package. Returns a struct with:
%     LAeq, LCeq, LZeq   - overall equivalent levels (A/C-weighted, and unweighted), dB
%     LAFmax, LASmax     - max Fast/Slow A-weighted level over the recording, dB
%     LA10, LA50, LA90   - statistical percentile levels from the Fast A-weighted trace
%                          (exceeded 10%/50%/90% of the time), dB
%     duration, numSamples, fs
%     tFast, LpAFast     - the Fast A-weighted level trace (for plotting/export)
%     tSlow, LpASlow     - the Slow A-weighted level trace (for plotting)
arguments
    p (:,1) double
    fs (1,1) double
    referencePressure (1,1) double = noiseanalyzer.referencePressure()
end
results = struct();
results.fs = fs;
results.numSamples = numel(p);
results.duration = numel(p)/fs;

pA = noiseanalyzer.applyWeighting(p, fs, "A");
pC = noiseanalyzer.applyWeighting(p, fs, "C");

results.LAeq = noiseanalyzer.equivalentLevel(pA, referencePressure);
results.LCeq = noiseanalyzer.equivalentLevel(pC, referencePressure);
results.LZeq = noiseanalyzer.equivalentLevel(p, referencePressure);

[results.tFast, results.LpAFast] = noiseanalyzer.timeWeightedLevel(pA, fs, ...
    noiseanalyzer.timeWeightingConstants("FAST"), referencePressure);
[results.tSlow, results.LpASlow] = noiseanalyzer.timeWeightedLevel(pA, fs, ...
    noiseanalyzer.timeWeightingConstants("SLOW"), referencePressure);

results.LAFmax = max(results.LpAFast);
results.LASmax = max(results.LpASlow);

results.LA10 = noiseanalyzer.percentileLevel(results.LpAFast, 90); % exceeded 10% of time
results.LA50 = noiseanalyzer.percentileLevel(results.LpAFast, 50); % exceeded 50% of time
results.LA90 = noiseanalyzer.percentileLevel(results.LpAFast, 10); % exceeded 90% of time (background)
end
