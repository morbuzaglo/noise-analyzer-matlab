function writeAnalysisCsv(results, filePath)
%WRITEANALYSISCSV Write the Fast A-weighted level time series to a CSV file
%   (time_s, LpA_Fast_dB), for downstream analysis/plotting outside MATLAB.
arguments
    results (1,1) struct
    filePath (1,1) string
end
T = table(results.tFast(:), results.LpAFast(:), 'VariableNames', {'time_s', 'LpA_Fast_dB'});
writetable(T, filePath);
end
