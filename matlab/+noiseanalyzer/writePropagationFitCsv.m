function writePropagationFitCsv(distances, measuredLevelsDbA, fitResult, filePath)
%WRITEPROPAGATIONFITCSV Write a per-distance-group measured-vs-predicted-vs-residual table, plus
%   the fitted parameters, to a CSV file. fitResult is the struct returned by
%   fitSourceLevelAndGroundFactor.
arguments
    distances (:,1) double
    measuredLevelsDbA (:,1) double
    fitResult (1,1) struct
    filePath (1,1) string
end
predicted = measuredLevelsDbA + fitResult.residuals;
T = table(distances, measuredLevelsDbA, predicted, fitResult.residuals, ...
    'VariableNames', {'Distance_m', 'Measured_dBA', 'Predicted_dBA', 'Residual_dB'});

summaryRow = table(NaN, NaN, NaN, NaN, 'VariableNames', T.Properties.VariableNames);
T = [T; summaryRow];

writetable(T, filePath);

[folder, name] = fileparts(filePath);
paramFilePath = fullfile(folder, name + "_parameters.csv");
paramT = table(fitResult.LwFit, fitResult.GFit, fitResult.RMSE, fitResult.R2, string(fitResult.solverUsed), ...
    'VariableNames', {'Lw_fit_dB', 'G_fit', 'RMSE_dB', 'R2', 'Solver'});
writetable(paramT, paramFilePath);
end
