function writeAnalysisReport(results, filePath, sourceFile)
%WRITEANALYSISREPORT Write a human-readable summary report (.txt) of analyzeRecording results.
%   If results has octaveBands/octaveLevels fields (see octaveBandSpectrumFFT), they're included.
arguments
    results (1,1) struct
    filePath (1,1) string
    sourceFile (1,1) string = ""
end
fid = fopen(filePath, 'w');
if fid == -1
    error('noiseanalyzer:writeAnalysisReport:cannotOpen', 'Could not open %s for writing.', filePath);
end
c = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'Noise Analyzer Report\n');
fprintf(fid, 'Generated: %s\n', string(datetime('now')));
if sourceFile ~= ""
    fprintf(fid, 'Source file: %s\n', sourceFile);
end
fprintf(fid, '\n');
fprintf(fid, 'Sample rate: %.3f Hz\n', results.fs);
fprintf(fid, 'Duration: %.3f s (%d samples)\n', results.duration, results.numSamples);
fprintf(fid, '\n');
fprintf(fid, 'LAeq = %.2f dB\n', results.LAeq);
fprintf(fid, 'LCeq = %.2f dB\n', results.LCeq);
fprintf(fid, 'LZeq = %.2f dB (unweighted)\n', results.LZeq);
fprintf(fid, '\n');
fprintf(fid, 'LAFmax = %.2f dB (max Fast-weighted A level)\n', results.LAFmax);
fprintf(fid, 'LASmax = %.2f dB (max Slow-weighted A level)\n', results.LASmax);
fprintf(fid, '\n');
fprintf(fid, 'LA10 = %.2f dB (exceeded 10%% of the time)\n', results.LA10);
fprintf(fid, 'LA50 = %.2f dB (exceeded 50%% of the time)\n', results.LA50);
fprintf(fid, 'LA90 = %.2f dB (exceeded 90%% of the time -- background level)\n', results.LA90);

if isfield(results, 'octaveBands') && isfield(results, 'octaveLevels')
    fprintf(fid, '\nOctave-band levels (FFT-based estimate -- NOT certified IEC 61260-1 filtering):\n');
    for i = 1:numel(results.octaveBands)
        fprintf(fid, '  %6d Hz : %7.2f dB\n', results.octaveBands(i), results.octaveLevels(i));
    end
end
end
