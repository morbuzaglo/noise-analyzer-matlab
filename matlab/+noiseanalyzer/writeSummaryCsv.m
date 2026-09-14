function writeSummaryCsv(results, filePath)
%WRITESUMMARYCSV Write the scalar summary metrics from analyzeRecording (plus, if present,
%   octaveBands/octaveLevels) to a CSV (Metric, Value) table.
arguments
    results (1,1) struct
    filePath (1,1) string
end
fields = {'fs', 'duration', 'numSamples', 'LAeq', 'LCeq', 'LZeq', ...
    'LAFmax', 'LASmax', 'LA10', 'LA50', 'LA90'};
names = {'fs_Hz', 'duration_s', 'numSamples', 'LAeq_dB', 'LCeq_dB', 'LZeq_dB', ...
    'LAFmax_dB', 'LASmax_dB', 'LA10_dB', 'LA50_dB', 'LA90_dB'};
values = cellfun(@(f) double(results.(f)), fields);

if isfield(results, 'octaveBands') && isfield(results, 'octaveLevels')
    for i = 1:numel(results.octaveBands)
        names{end+1} = sprintf('L_%dHz_dB', results.octaveBands(i)); %#ok<AGROW>
        values(end+1) = results.octaveLevels(i); %#ok<AGROW>
    end
end

T = table(names', values', 'VariableNames', {'Metric', 'Value'});
writetable(T, filePath);
end
