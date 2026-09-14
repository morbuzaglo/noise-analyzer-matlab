function [t, p, fs] = loadPressureTimeData(filePath, fallbackFs)
%LOADPRESSURETIMEDATA Load a raw sound-pressure recording (Pa vs s) from CSV/TXT/MAT.
%   Supports:
%     - CSV/TXT with a header row containing time/t/seconds and pressure/p/pa columns (any order)
%     - CSV/TXT with exactly two unlabeled numeric columns, assumed [time, pressure]
%     - CSV/TXT with exactly one numeric column, assumed pressure-only — fallbackFs required
%     - MAT file with variables matching (case-insensitive) time/t/seconds and pressure/p/pa, or
%       a single pressure-only vector variable — fallbackFs required
%   Returns t (s, column vector, shifted to start at 0), p (Pa, column vector), fs (Hz, scalar —
%   derived from median(diff(t)) when a time column is present, otherwise fallbackFs).
arguments
    filePath (1,1) string
    fallbackFs (1,1) double = NaN
end
[~, ~, ext] = fileparts(filePath);

switch lower(ext)
    case '.mat'
        s = load(filePath);
        [t, p] = extractFromStruct(s);
    otherwise
        [t, p] = extractFromTable(filePath);
end

if isempty(t)
    if isnan(fallbackFs)
        error('noiseanalyzer:loadPressureTimeData:noSampleRate', ...
            'No time column found and no fallbackFs provided -- cannot determine sample rate.');
    end
    fs = fallbackFs;
    t = (0:numel(p)-1)' / fs;
else
    dt = median(diff(t));
    fs = 1/dt;
    t = t - t(1);
end
p = double(p(:));
t = double(t(:));
end

function [t, p] = extractFromTable(filePath)
opts = detectImportOptions(filePath);
T = readtable(filePath, opts);
varNames = lower(string(T.Properties.VariableNames));

timeCol = find(matches(varNames, ["time", "t", "seconds", "s"]), 1);
pressureCol = find(matches(varNames, ["pressure", "p", "pa"]), 1);

if ~isempty(timeCol) && ~isempty(pressureCol)
    t = T{:, timeCol};
    p = T{:, pressureCol};
elseif width(T) >= 2
    t = T{:, 1};
    p = T{:, 2};
elseif width(T) == 1
    t = [];
    p = T{:, 1};
else
    error('noiseanalyzer:loadPressureTimeData:emptyFile', 'No numeric data found in %s.', filePath);
end
end

function [t, p] = extractFromStruct(s)
fn = fieldnames(s);
fnLower = lower(fn);

timeIdx = find(matches(fnLower, ["time", "t", "seconds"]), 1);
pressureIdx = find(matches(fnLower, ["pressure", "p", "pa"]), 1);

if ~isempty(timeIdx) && ~isempty(pressureIdx)
    t = s.(fn{timeIdx});
    p = s.(fn{pressureIdx});
elseif ~isempty(pressureIdx)
    t = [];
    p = s.(fn{pressureIdx});
elseif numel(fn) == 1
    t = [];
    p = s.(fn{1});
else
    error('noiseanalyzer:loadPressureTimeData:ambiguousMat', ...
        'Could not identify pressure/time variables in MAT file; found: %s', strjoin(fn, ', '));
end
end
