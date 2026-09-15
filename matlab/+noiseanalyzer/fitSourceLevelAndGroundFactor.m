function fitResult = fitSourceLevelAndGroundFactor(distances, measuredLevelsDbA, opts)
%FITSOURCELEVELANDGROUNDFACTOR Fit unknown source power level Lw and/or ground factor G to
%   multi-microphone measured levels at several distances, by minimizing the residual between
%   noiseanalyzer.predictedSoundPressureLevel(...) and the measured data. This is the
%   parameter-optimization step nothing in the package did before: comparing the ISO 9613-2
%   theoretical attenuation curve against real multi-radius measurements and solving for the
%   unknown/guessed parameters that make them agree.
%
%   distances/measuredLevelsDbA should already be one value per distance (e.g. the output of
%   groupLevelsByDistance) -- at least 2 distinct distances are required to fit 2 parameters
%   (more are needed for a well-conditioned fit; a warning is issued with too few points).
%
%   opts.FitTargets selects which of "Lw","G" are free parameters (default both); a target left
%   out is held fixed at opts.FixedLw / opts.FixedG. All other propagation inputs
%   (Temperature/RH/Pressure/heights/Dc/C0/spectrum shape/etc.) are fixed, matching
%   predictedSoundPressureLevel's own defaults unless overridden.
%
%   opts.Solver: "lsqnonlin" (default, bounded, needs Optimization Toolbox), "fmincon" (bounded,
%   Optimization Toolbox), "ga"/"particleswarm" (global, Global Optimization Toolbox), or
%   "fminsearch" (unconstrained, ships with base MATLAB, used automatically as a fallback if
%   Optimization Toolbox isn't licensed and the caller left the default solver).
%
%   fitResult fields: LwFit, GFit, residuals, RMSE, R2, predictedCurve (struct with Distance/Level
%   for a dense sweep, for plotting), ci (95% confidence interval on the fitted parameters, or
%   [] if not available), solverUsed, exitflag.
arguments
    distances (:,1) double
    measuredLevelsDbA (:,1) double
    opts.Freq (1,:) double = noiseanalyzer.iso9613OctaveBands()
    opts.SpectrumShapeDb (1,:) double = zeros(1, numel(noiseanalyzer.iso9613OctaveBands()))
    opts.TemperatureC (1,1) double = 15
    opts.RelativeHumidityPct (1,1) double = 70
    opts.PressureKPa (1,1) double = 101.325
    opts.hs (1,1) double = 1.5
    opts.hr (1,1) double = 1.5
    opts.Dc (1,1) double = 0
    opts.C0 (1,1) double = 0
    opts.FitTargets (1,:) string {mustBeMember(opts.FitTargets, ["Lw", "G"])} = ["Lw", "G"]
    opts.FixedG (1,1) double = 0.5
    opts.FixedLw (1,1) double = NaN
    opts.InitialLw (1,1) double = NaN   % auto via estimateSourcePowerLevelFromMeasurement if NaN
    opts.InitialG (1,1) double = 0.5
    opts.Solver (1,1) string {mustBeMember(opts.Solver, ["lsqnonlin", "fminsearch", "fmincon", "ga", "particleswarm"])} = "lsqnonlin"
end
if numel(distances) ~= numel(measuredLevelsDbA)
    error('noiseanalyzer:fitSourceLevelAndGroundFactor:SizeMismatch', ...
        'distances and measuredLevelsDbA must have the same number of elements.');
end
if numel(distances) < 2
    error('noiseanalyzer:fitSourceLevelAndGroundFactor:TooFewDistances', ...
        'At least 2 distinct distances are required to fit source level and ground factor.');
elseif numel(distances) < numel(opts.FitTargets) + 1
    warning('noiseanalyzer:fitSourceLevelAndGroundFactor:UnderdeterminedFit', ...
        'Only %d distance(s) for %d free parameter(s); the fit will be poorly conditioned.', ...
        numel(distances), numel(opts.FitTargets));
end

fitLw = ismember("Lw", opts.FitTargets);
fitG = ismember("G", opts.FitTargets);

if isnan(opts.InitialLw)
    farIdx = distances == max(distances);
    initialLwGuess = noiseanalyzer.estimateSourcePowerLevelFromMeasurement( ...
        mean(measuredLevelsDbA(farIdx)), opts.SpectrumShapeDb, opts.Dc, ...
        noiseanalyzer.geometricalDivergence(max(distances)), 0, 0, 0, 0, opts.Freq);
else
    initialLwGuess = opts.InitialLw;
end

forward = @(Lw, G, d) noiseanalyzer.predictedSoundPressureLevel(Lw + opts.SpectrumShapeDb, d, ...
    'Freq', opts.Freq, 'TemperatureC', opts.TemperatureC, 'RelativeHumidityPct', opts.RelativeHumidityPct, ...
    'PressureKPa', opts.PressureKPa, 'Gs', G, 'Gr', G, 'Gm', G, 'hs', opts.hs, 'hr', opts.hr, ...
    'Dc', opts.Dc, 'C0', opts.C0);

theta0 = [];
lb = [];
ub = [];
if fitLw
    theta0(end+1) = initialLwGuess; lb(end+1) = initialLwGuess - 60; ub(end+1) = initialLwGuess + 60;
end
if fitG
    theta0(end+1) = opts.InitialG; lb(end+1) = 0; ub(end+1) = 1;
end

    function Lw = paramLw(theta)
        if fitLw, Lw = theta(1); else, Lw = opts.FixedLw; end
    end
    function G = paramG(theta)
        if fitG, G = theta(1 + fitLw); else, G = opts.FixedG; end
    end
    function r = residualFcn(theta)
        Lw = paramLw(theta);
        G = paramG(theta);
        predicted = arrayfun(@(d) forward(Lw, G, d), distances);
        r = predicted - measuredLevelsDbA;
    end
    function s = sumSquares(theta)
        r = residualFcn(theta);
        s = sum(r.^2);
    end

solver = opts.Solver;
if solver == "lsqnonlin" && ~license('test', 'Optimization_Toolbox')
    solver = "fminsearch";
end

exitflag = 1;
jacobian = [];
switch solver
    case "lsqnonlin"
        optimOpts = optimoptions('lsqnonlin', 'Display', 'off');
        [thetaFit, ~, residualsAtFit, exitflag, ~, ~, jacobian] = lsqnonlin(@residualFcn, theta0, lb, ub, optimOpts);
    case "fminsearch"
        [thetaFit, ~, exitflag] = fminsearch(@sumSquares, theta0, optimset('Display', 'off'));
        residualsAtFit = residualFcn(thetaFit);
    case "fmincon"
        optimOpts = optimoptions('fmincon', 'Display', 'off');
        [thetaFit, ~, exitflag] = fmincon(@sumSquares, theta0, [], [], [], [], lb, ub, [], optimOpts);
        residualsAtFit = residualFcn(thetaFit);
    case "ga"
        optimOpts = optimoptions('ga', 'Display', 'off');
        [thetaFit, ~, exitflag] = ga(@sumSquares, numel(theta0), [], [], [], [], lb, ub, [], optimOpts);
        residualsAtFit = residualFcn(thetaFit);
    case "particleswarm"
        optimOpts = optimoptions('particleswarm', 'Display', 'off');
        [thetaFit, ~, exitflag] = particleswarm(@sumSquares, numel(theta0), lb, ub, optimOpts);
        residualsAtFit = residualFcn(thetaFit);
end

fitResult = struct();
fitResult.LwFit = paramLw(thetaFit);
fitResult.GFit = paramG(thetaFit);
fitResult.residuals = residualsAtFit;
fitResult.RMSE = sqrt(mean(residualsAtFit.^2));
ssTot = sum((measuredLevelsDbA - mean(measuredLevelsDbA)).^2);
if ssTot > 0
    fitResult.R2 = 1 - sum(residualsAtFit.^2) / ssTot;
else
    fitResult.R2 = NaN;
end

denseDistance = linspace(min(distances), max(distances), 100)';
fitResult.predictedCurve = struct('Distance', denseDistance, ...
    'Level', arrayfun(@(d) forward(fitResult.LwFit, fitResult.GFit, d), denseDistance));

fitResult.ci = [];
if solver == "lsqnonlin" && license('test', 'Statistics_Toolbox') && numel(distances) > numel(theta0)
    try
        fitResult.ci = nlparci(thetaFit, residualsAtFit, 'jacobian', jacobian);
    catch
        fitResult.ci = [];
    end
end

fitResult.solverUsed = solver;
fitResult.exitflag = exitflag;
end
