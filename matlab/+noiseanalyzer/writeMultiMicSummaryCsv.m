function writeMultiMicSummaryCsv(T, filePath, aggregationMethod)
%WRITEMULTIMICSUMMARYCSV Write a per-microphone summary table plus one aggregate row (computed
%   over Include==true rows only, via aggregateLevels) to a CSV file.
%   T must be a table with columns Label, Distance_m, Include (logical), and any subset of the
%   metric columns LAeq_dB, LCeq_dB, LZeq_dB, LAFmax_dB, LASmax_dB, LA10_dB, LA50_dB, LA90_dB
%   (only columns present in T are aggregated).
arguments
    T table
    filePath (1,1) string
    aggregationMethod (1,1) string {mustBeMember(aggregationMethod, ["mean", "max"])} = "mean"
end
metricCols = ["LAeq_dB", "LCeq_dB", "LZeq_dB", "LAFmax_dB", "LASmax_dB", "LA10_dB", "LA50_dB", "LA90_dB"];
included = T(T.Include, :);

aggRow = T(1, :);
aggRow.Label = "AGGREGATE (" + aggregationMethod + ")";
aggRow.Distance_m = NaN;
aggRow.Include = true;
for c = metricCols
    if ismember(c, string(T.Properties.VariableNames))
        aggRow.(c) = noiseanalyzer.aggregateLevels(included.(c), aggregationMethod);
    end
end

writetable([T; aggRow], filePath);
end
