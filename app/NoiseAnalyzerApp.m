classdef NoiseAnalyzerApp < matlab.apps.AppBase
    %NOISEANALYZERAPP Interactive app for analyzing raw sound-pressure recordings (Pa vs s) from
    %   one or more microphones at known distances from a sound source: load data, configure
    %   settings (in-app table or a loadable/savable .csv config file), trim each recording to
    %   its relevant time range, listen to it, compute A-weighted level and related standard
    %   metrics per microphone, choose which microphones to include and how to combine them
    %   (energetic mean or max), view plots including level vs. distance, and export a combined
    %   CSV report. All computation is delegated to the noiseanalyzer.* functions -- this class
    %   is a thin UI wrapper, not where the acoustics logic lives.
    %
    %   Written as a uifigure-based classdef app (App Designer's own underlying format) rather
    %   than a packaged .mlapp binary, so it stays readable/diffable in source control. Run it
    %   with: app = NoiseAnalyzerApp
    %
    %   Note on interactivity: time-range trimming uses numeric start/end fields (applied via a
    %   button) with the selected range highlighted directly on the waveform plot, rather than a
    %   mouse-draggable region -- Image Processing Toolbox (which provides drawrectangle/
    %   images.roi.Rectangle) is not available on the machine this was built on, so a toolbox-free
    %   approach was used. Numbers + a highlighted plot region were judged close enough to "in the
    %   plot itself" without that dependency.

    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        ControlPanel                  matlab.ui.container.Panel
        ControlGrid                    matlab.ui.container.GridLayout

        AddMicButton                     matlab.ui.control.Button
        MicTable                          matlab.ui.control.Table
        RemoveMicButton                   matlab.ui.control.Button

        SettingsLabel                     matlab.ui.control.Label
        SettingsTable                      matlab.ui.control.Table
        ConfigButtonGrid                    matlab.ui.container.GridLayout
        LoadConfigButton                     matlab.ui.control.Button
        SaveConfigButton                     matlab.ui.control.Button

        AnalyzeAllButton                  matlab.ui.control.Button

        StatusGrid                        matlab.ui.container.GridLayout
        StatusLamp                          matlab.ui.control.Lamp
        StatusLabel                         matlab.ui.control.Label

        OutputFolderLabel                 matlab.ui.control.Label
        OutputFolderGrid                   matlab.ui.container.GridLayout
        OutputFolderEditField                matlab.ui.control.EditField
        BrowseOutputButton                   matlab.ui.control.Button
        ExportButton                      matlab.ui.control.Button

        TabGroup                     matlab.ui.container.TabGroup
        WaveformTab                    matlab.ui.container.Tab
        WaveformGrid                     matlab.ui.container.GridLayout
        WaveformAxes                      matlab.ui.control.UIAxes
        TrimControlGrid                   matlab.ui.container.GridLayout
        TrimStartLabel                       matlab.ui.control.Label
        TrimStartField                       matlab.ui.control.NumericEditField
        TrimEndLabel                         matlab.ui.control.Label
        TrimEndField                         matlab.ui.control.NumericEditField
        ApplyTrimButton                      matlab.ui.control.Button
        ResetTrimButton                      matlab.ui.control.Button
        PlayButton                           matlab.ui.control.Button
        StopButton                           matlab.ui.control.Button

        LevelTab                       matlab.ui.container.Tab
        LevelGrid                        matlab.ui.container.GridLayout
        LevelAxes                          matlab.ui.control.UIAxes

        SpectrumTab                    matlab.ui.container.Tab
        SpectrumGrid                      matlab.ui.container.GridLayout
        SpectrumAxes                        matlab.ui.control.UIAxes

        DistanceTab                    matlab.ui.container.Tab
        DistanceGrid                      matlab.ui.container.GridLayout
        DistanceMetricDropDown              matlab.ui.control.DropDown
        PropagationPanel                    matlab.ui.container.Panel
        PropagationGrid                       matlab.ui.container.GridLayout
        TemperatureField                          matlab.ui.control.NumericEditField
        HumidityField                              matlab.ui.control.NumericEditField
        PressureField                              matlab.ui.control.NumericEditField
        SourceHeightField                          matlab.ui.control.NumericEditField
        ReceiverHeightField                        matlab.ui.control.NumericEditField
        GroundFactorField                          matlab.ui.control.NumericEditField
        DirectivityField                           matlab.ui.control.NumericEditField
        ToleranceField                             matlab.ui.control.NumericEditField
        FitLwCheckBox                              matlab.ui.control.CheckBox
        FitGCheckBox                               matlab.ui.control.CheckBox
        SolverDropDown                             matlab.ui.control.DropDown
        FitModelButton                             matlab.ui.control.Button
        FitResultsLabel                            matlab.ui.control.Label
        DistanceAxes                        matlab.ui.control.UIAxes
        ResidualsAxes                       matlab.ui.control.UIAxes

        SummaryTab                     matlab.ui.container.Tab
        SummaryGrid                      matlab.ui.container.GridLayout
        SummaryTable                       matlab.ui.control.Table
    end

    properties (Access = private)
        Mics = struct('Label', {}, 'FilePath', {}, 'Distance', {}, 'Include', {}, ...
            'RawTime', {}, 'RawPressure', {}, 'Fs', {}, 'TrimStart', {}, 'TrimEnd', {}, ...
            'Status', {}, 'Results', {})
        SelectedMicIndex double = 0
        Player = []
        FitResult = [] % result struct from noiseanalyzer.fitSourceLevelAndGroundFactor, or [] until Fit Model is run
    end

    methods (Access = private)

        function settings = getSettings(app)
            T = app.SettingsTable.Data;
            settings = struct();
            for i = 1:height(T)
                settings.(matlab.lang.makeValidName(T.Setting{i})) = string(T.Value{i});
            end
        end

        function fs = getFallbackSampleRate(app)
            s = app.getSettings();
            fs = NaN;
            if isfield(s, 'SampleRateHz') && strlength(s.SampleRateHz) > 0
                val = str2double(s.SampleRateHz);
                if ~isnan(val) && val > 0
                    fs = val;
                end
            end
        end

        function p0 = getReferencePressure(app)
            s = app.getSettings();
            p0 = noiseanalyzer.referencePressure();
            if isfield(s, 'ReferencePressurePa') && strlength(s.ReferencePressurePa) > 0
                val = str2double(s.ReferencePressurePa);
                if ~isnan(val) && val > 0
                    p0 = val;
                end
            end
        end

        function tw = getTimeWeighting(app)
            s = app.getSettings();
            tw = "Fast";
            if isfield(s, 'TimeWeighting') && lower(s.TimeWeighting) == "slow"
                tw = "Slow";
            end
        end

        function method = getAggregationMethod(app)
            s = app.getSettings();
            method = "mean";
            if isfield(s, 'AggregationMethod') && lower(s.AggregationMethod) == "max"
                method = "max";
            end
        end

        function s = getPropagationSettings(app)
            % Gathers the Propagation Model panel into the Name-Value options
            % noiseanalyzer.predictedSoundPressureLevel / fitSourceLevelAndGroundFactor expect.
            s = struct();
            s.TemperatureC = app.TemperatureField.Value;
            s.RelativeHumidityPct = app.HumidityField.Value;
            s.PressureKPa = app.PressureField.Value;
            s.hs = app.SourceHeightField.Value;
            s.hr = app.ReceiverHeightField.Value;
            s.FixedG = app.GroundFactorField.Value;
            s.Dc = app.DirectivityField.Value;
            s.Tolerance = app.ToleranceField.Value;
            s.FitLw = app.FitLwCheckBox.Value;
            s.FitG = app.FitGCheckBox.Value;
            s.Solver = app.SolverDropDown.Value;
        end

        function refreshFitResultsLabel(app)
            if isempty(app.FitResult)
                app.FitResultsLabel.Text = 'No fit yet -- set the propagation parameters above and click Fit Model.';
                return
            end
            r = app.FitResult;
            app.FitResultsLabel.Text = sprintf( ...
                'Fitted Lw = %.1f dB   |   Fitted ground factor G = %.2f   |   RMSE = %.2f dB   |   R^2 = %.3f   |   solver = %s (exitflag %d)', ...
                r.LwFit, r.GFit, r.RMSE, r.R2, r.solverUsed, r.exitflag);
        end

        function setBusy(app, text)
            app.StatusLamp.Color = [0.95, 0.65, 0.1];
            app.StatusLabel.Text = text;
            drawnow;
        end

        function setDone(app, text)
            app.StatusLamp.Color = [0.2, 0.7, 0.3];
            app.StatusLabel.Text = text;
            drawnow;
        end

        function [t, p] = trimmedSignal(~, mic)
            mask = mic.RawTime >= mic.TrimStart & mic.RawTime <= mic.TrimEnd;
            t = mic.RawTime(mask);
            p = mic.RawPressure(mask);
        end

        function refreshMicTable(app)
            n = numel(app.Mics);
            if n == 0
                app.MicTable.Data = table('Size', [0 5], ...
                    'VariableTypes', {'string','double','logical','string','double'}, ...
                    'VariableNames', {'Label','Distance_m','Include','Status','LAeq_dB'});
                return
            end
            Label = strings(n,1); Distance_m = zeros(n,1); Include = false(n,1);
            Status = strings(n,1); LAeq_dB = nan(n,1);
            for i = 1:n
                Label(i) = app.Mics(i).Label;
                Distance_m(i) = app.Mics(i).Distance;
                Include(i) = app.Mics(i).Include;
                Status(i) = app.Mics(i).Status;
                if isfield(app.Mics(i).Results, 'LAeq')
                    LAeq_dB(i) = app.Mics(i).Results.LAeq;
                end
            end
            app.MicTable.Data = table(Label, Distance_m, Include, Status, LAeq_dB);
        end

        function refreshSummaryTable(app)
            T = app.buildResultsTable();
            app.SummaryTable.Data = T;
        end

        function T = buildResultsTable(app)
            n = numel(app.Mics);
            Label = strings(n,1); Distance_m = zeros(n,1); Include = false(n,1);
            fields = {'LAeq','LCeq','LZeq','LAFmax','LASmax','LA10','LA50','LA90'};
            names = {'LAeq_dB','LCeq_dB','LZeq_dB','LAFmax_dB','LASmax_dB','LA10_dB','LA50_dB','LA90_dB'};
            vals = nan(n, numel(fields));
            for i = 1:n
                Label(i) = app.Mics(i).Label;
                Distance_m(i) = app.Mics(i).Distance;
                Include(i) = app.Mics(i).Include;
                if isfield(app.Mics(i).Results, 'LAeq')
                    for k = 1:numel(fields)
                        vals(i,k) = app.Mics(i).Results.(fields{k});
                    end
                end
            end
            T = table(Label, Distance_m, Include);
            for k = 1:numel(names)
                T.(names{k}) = vals(:,k);
            end
        end

        function plotWaveform(app)
            cla(app.WaveformAxes);
            if app.SelectedMicIndex < 1 || app.SelectedMicIndex > numel(app.Mics)
                return
            end
            mic = app.Mics(app.SelectedMicIndex);
            hold(app.WaveformAxes, 'on');
            plot(app.WaveformAxes, mic.RawTime, mic.RawPressure, 'Color', [0.75 0.75 0.75]);
            [tTrim, pTrim] = app.trimmedSignal(mic);
            plot(app.WaveformAxes, tTrim, pTrim, 'Color', [0.2 0.4 0.7]);
            xline(app.WaveformAxes, mic.TrimStart, '--', 'Color', [0.8 0.2 0.2]);
            xline(app.WaveformAxes, mic.TrimEnd, '--', 'Color', [0.8 0.2 0.2]);
            hold(app.WaveformAxes, 'off');
            xlabel(app.WaveformAxes, 'Time (s)');
            ylabel(app.WaveformAxes, 'Pressure (Pa)');
            title(app.WaveformAxes, sprintf('%s -- gray = full recording, blue = selected range', mic.Label));
            grid(app.WaveformAxes, 'on');

            app.TrimStartField.Value = mic.TrimStart;
            app.TrimEndField.Value = mic.TrimEnd;
        end

        function plotLevel(app)
            cla(app.LevelAxes);
            if app.SelectedMicIndex < 1 || app.SelectedMicIndex > numel(app.Mics)
                return
            end
            r = app.Mics(app.SelectedMicIndex).Results;
            if ~isfield(r, 'tFast')
                return
            end
            if app.getTimeWeighting() == "Slow"
                t = r.tSlow; lvl = r.LpASlow; lbl = 'L_{A,Slow} (dB)';
            else
                t = r.tFast; lvl = r.LpAFast; lbl = 'L_{A,Fast} (dB)';
            end
            plot(app.LevelAxes, t, lvl, 'Color', [0.75 0.2 0.2]);
            xlabel(app.LevelAxes, 'Time (s)');
            ylabel(app.LevelAxes, lbl);
            title(app.LevelAxes, 'A-weighted time-weighted level');
            grid(app.LevelAxes, 'on');
        end

        function plotSpectrum(app)
            cla(app.SpectrumAxes);
            if app.SelectedMicIndex < 1 || app.SelectedMicIndex > numel(app.Mics)
                return
            end
            r = app.Mics(app.SelectedMicIndex).Results;
            if ~isfield(r, 'octaveBands')
                return
            end
            labels = string(r.octaveBands) + " Hz";
            cats = categorical(labels, labels);
            bar(app.SpectrumAxes, cats, r.octaveLevels, 'FaceColor', [0.3 0.6 0.4]);
            xlabel(app.SpectrumAxes, 'Octave band');
            ylabel(app.SpectrumAxes, 'Level (dB)');
            title(app.SpectrumAxes, 'Octave-band spectrum (FFT estimate)');
            grid(app.SpectrumAxes, 'on');
        end

        function [groupedDistance, groupedLevel] = getGroupedLAeq(app)
            % Included, analyzed mics' LAeq grouped by distance (noiseanalyzer.groupLevelsByDistance)
            % -- the data both Fit Model and the residuals plot operate on.
            T = app.buildResultsTable();
            hasResult = T.Include & ~isnan(T.LAeq_dB);
            groupedDistance = [];
            groupedLevel = [];
            if ~any(hasResult)
                return
            end
            [groupedDistance, groupedLevel] = noiseanalyzer.groupLevelsByDistance( ...
                T.Distance_m(hasResult), T.LAeq_dB(hasResult), app.getAggregationMethod(), ...
                app.ToleranceField.Value);
        end

        function plotDistance(app)
            cla(app.DistanceAxes);
            metric = app.DistanceMetricDropDown.Value;
            field = metric + "_dB";
            T = app.buildResultsTable();
            hasResult = ~isnan(T.(field));
            if ~any(hasResult)
                return
            end
            T = T(hasResult, :);
            incl = T.Include;
            hold(app.DistanceAxes, 'on');
            if any(incl)
                scatter(app.DistanceAxes, T.Distance_m(incl), T.(field)(incl), 60, ...
                    [0.2 0.4 0.7], 'filled', 'DisplayName', 'Included (per mic)');
            end
            if any(~incl)
                scatter(app.DistanceAxes, T.Distance_m(~incl), T.(field)(~incl), 60, ...
                    [0.6 0.6 0.6], 'DisplayName', 'Excluded');
            end
            if any(incl)
                [groupedDistance, groupedLevel] = noiseanalyzer.groupLevelsByDistance( ...
                    T.Distance_m(incl), T.(field)(incl), app.getAggregationMethod(), app.ToleranceField.Value);
                plot(app.DistanceAxes, groupedDistance, groupedLevel, 'd-', 'Color', [0.8 0.3 0.1], ...
                    'MarkerFaceColor', [0.8 0.3 0.1], 'LineWidth', 1.5, ...
                    'DisplayName', sprintf('%s (%s) per distance', metric, app.getAggregationMethod()));
            end
            if ~isempty(app.FitResult) && metric == "LAeq"
                c = app.FitResult.predictedCurve;
                plot(app.DistanceAxes, c.Distance, c.Level, '-', 'Color', [0.2 0.6 0.2], ...
                    'LineWidth', 1.5, 'DisplayName', 'Fitted ISO 9613-2 model');
            end
            hold(app.DistanceAxes, 'off');
            xlabel(app.DistanceAxes, 'Distance from source (m)');
            ylabel(app.DistanceAxes, metric + " (dB)");
            title(app.DistanceAxes, metric + " vs. distance");
            legend(app.DistanceAxes, 'Location', 'best');
            grid(app.DistanceAxes, 'on');
        end

        function plotResiduals(app)
            cla(app.ResidualsAxes);
            if isempty(app.FitResult)
                return
            end
            [groupedDistance, ~] = app.getGroupedLAeq();
            r = app.FitResult.residuals(:);
            if numel(r) ~= numel(groupedDistance)
                % Mic selection/settings changed since the last fit -- stale, skip rather than
                % plot mismatched data; re-run Fit Model to refresh.
                return
            end
            stem(app.ResidualsAxes, groupedDistance, r, 'filled', 'Color', [0.6 0.2 0.6]);
            hold(app.ResidualsAxes, 'on');
            yline(app.ResidualsAxes, 0, 'k--');
            hold(app.ResidualsAxes, 'off');
            xlabel(app.ResidualsAxes, 'Distance from source (m)');
            ylabel(app.ResidualsAxes, 'Measured - predicted (dB)');
            title(app.ResidualsAxes, 'Fit residuals (LAeq)');
            grid(app.ResidualsAxes, 'on');
        end

        function refreshAll(app)
            app.refreshMicTable();
            app.plotWaveform();
            app.plotLevel();
            app.plotSpectrum();
            app.plotDistance();
            app.plotResiduals();
            app.refreshSummaryTable();
        end

    end

    methods (Access = private)

        function AddMicButtonPushed(app, ~)
            [files, folder] = uigetfile({'*.csv;*.txt;*.mat', 'Sound data (*.csv, *.txt, *.mat)'}, ...
                'Select microphone recording(s)', 'MultiSelect', 'on');
            if isequal(files, 0)
                return
            end
            if ischar(files)
                files = {files};
            end
            app.setBusy(sprintf('Loading %d file(s)...', numel(files)));
            fallbackFs = app.getFallbackSampleRate();
            failed = {};
            for i = 1:numel(files)
                fullPath = fullfile(folder, files{i});
                try
                    [t, p, fs] = noiseanalyzer.loadPressureTimeData(fullPath, fallbackFs);
                catch ME
                    failed{end+1} = sprintf('%s: %s', files{i}, ME.message); %#ok<AGROW>
                    continue
                end
                [~, baseName] = fileparts(files{i});
                newMic = struct('Label', string(baseName), 'FilePath', string(fullPath), ...
                    'Distance', 0, 'Include', true, 'RawTime', t, 'RawPressure', p, 'Fs', fs, ...
                    'TrimStart', t(1), 'TrimEnd', t(end), 'Status', "Loaded", 'Results', struct());
                app.Mics(end+1) = newMic;
            end
            if isempty(app.Mics)
                app.setDone('Ready.');
            else
                app.SelectedMicIndex = numel(app.Mics);
                app.setDone(sprintf('%d microphone(s) loaded.', numel(app.Mics)));
            end
            app.refreshAll();
            if ~isempty(failed)
                uialert(app.UIFigure, strjoin(failed, newline), 'Some files failed to load');
            end
        end

        function RemoveMicButtonPushed(app, ~)
            if app.SelectedMicIndex < 1 || app.SelectedMicIndex > numel(app.Mics)
                return
            end
            app.Mics(app.SelectedMicIndex) = [];
            app.SelectedMicIndex = min(app.SelectedMicIndex, numel(app.Mics));
            app.refreshAll();
        end

        function MicTableCellEdit(app, event)
            row = event.Indices(1);
            col = event.Indices(2);
            if row < 1 || row > numel(app.Mics)
                return
            end
            switch col
                case 2
                    app.Mics(row).Distance = event.NewData;
                case 3
                    app.Mics(row).Include = logical(event.NewData);
            end
            app.plotDistance();
        end

        function MicTableCellSelection(app, event)
            if isempty(event.Indices)
                return
            end
            row = event.Indices(1,1);
            if row >= 1 && row <= numel(app.Mics)
                app.SelectedMicIndex = row;
                app.plotWaveform();
                app.plotLevel();
                app.plotSpectrum();
            end
        end

        function ApplyTrimButtonPushed(app, ~)
            if app.SelectedMicIndex < 1 || app.SelectedMicIndex > numel(app.Mics)
                return
            end
            mic = app.Mics(app.SelectedMicIndex);
            newStart = app.TrimStartField.Value;
            newEnd = app.TrimEndField.Value;
            if newStart < mic.RawTime(1) || newEnd > mic.RawTime(end) || newStart >= newEnd
                uialert(app.UIFigure, sprintf('Trim range must satisfy %.3f <= start < end <= %.3f.', ...
                    mic.RawTime(1), mic.RawTime(end)), 'Invalid trim range');
                return
            end
            app.Mics(app.SelectedMicIndex).TrimStart = newStart;
            app.Mics(app.SelectedMicIndex).TrimEnd = newEnd;
            app.Mics(app.SelectedMicIndex).Status = "Loaded";
            app.Mics(app.SelectedMicIndex).Results = struct();
            app.refreshAll();
        end

        function ResetTrimButtonPushed(app, ~)
            if app.SelectedMicIndex < 1 || app.SelectedMicIndex > numel(app.Mics)
                return
            end
            mic = app.Mics(app.SelectedMicIndex);
            app.Mics(app.SelectedMicIndex).TrimStart = mic.RawTime(1);
            app.Mics(app.SelectedMicIndex).TrimEnd = mic.RawTime(end);
            app.Mics(app.SelectedMicIndex).Status = "Loaded";
            app.Mics(app.SelectedMicIndex).Results = struct();
            app.refreshAll();
        end

        function PlayButtonPushed(app, ~)
            if app.SelectedMicIndex < 1 || app.SelectedMicIndex > numel(app.Mics)
                return
            end
            mic = app.Mics(app.SelectedMicIndex);
            [~, pTrim] = app.trimmedSignal(mic);
            if isempty(pTrim)
                return
            end
            audioData = pTrim / (max(abs(pTrim)) + eps) * 0.9;
            try
                if ~isempty(app.Player) && isvalid(app.Player)
                    stop(app.Player);
                end
                app.Player = audioplayer(audioData, mic.Fs);
                play(app.Player);
            catch ME
                uialert(app.UIFigure, ME.message, 'Playback failed');
            end
        end

        function StopButtonPushed(app, ~)
            if ~isempty(app.Player) && isvalid(app.Player)
                stop(app.Player);
            end
        end

        function AnalyzeAllButtonPushed(app, ~)
            if isempty(app.Mics)
                uialert(app.UIFigure, 'Add at least one microphone recording first.', 'No data');
                return
            end
            app.setBusy('Analyzing...');
            p0 = app.getReferencePressure();
            bands = noiseanalyzer.iso9613OctaveBands();
            failed = {};
            for i = 1:numel(app.Mics)
                mic = app.Mics(i);
                [~, pTrim] = app.trimmedSignal(mic);
                try
                    results = noiseanalyzer.analyzeRecording(pTrim, mic.Fs, p0);
                    results.octaveBands = bands;
                    results.octaveLevels = noiseanalyzer.octaveBandSpectrumFFT(pTrim, mic.Fs, bands, p0);
                    app.Mics(i).Results = results;
                    app.Mics(i).Status = "Analyzed";
                catch ME
                    failed{end+1} = sprintf('%s: %s', mic.Label, ME.message); %#ok<AGROW>
                    app.Mics(i).Status = "Error";
                end
            end
            app.setDone('Analysis complete.');
            app.refreshAll();
            if ~isempty(failed)
                uialert(app.UIFigure, strjoin(failed, newline), 'Some microphones failed to analyze');
            end
        end

        function ExportButtonPushed(app, ~)
            T = app.buildResultsTable();
            if isempty(T) || all(isnan(T.LAeq_dB))
                uialert(app.UIFigure, 'Run Analyze All first.', 'Nothing to export');
                return
            end
            outFolder = strtrim(app.OutputFolderEditField.Value);
            if isempty(outFolder)
                outFolder = uigetdir(pwd, 'Select output folder');
                if isequal(outFolder, 0)
                    return
                end
                app.OutputFolderEditField.Value = outFolder;
            end
            app.setBusy('Exporting...');
            try
                summaryPath = fullfile(outFolder, "noise_analysis_summary.csv");
                noiseanalyzer.writeMultiMicSummaryCsv(T, summaryPath, app.getAggregationMethod());
                for i = 1:numel(app.Mics)
                    if isfield(app.Mics(i).Results, 'LAeq')
                        noiseanalyzer.writeAnalysisCsv(app.Mics(i).Results, ...
                            fullfile(outFolder, app.Mics(i).Label + "_timeseries.csv"));
                    end
                end
                if ~isempty(app.FitResult)
                    [groupedDistance, groupedLevel] = app.getGroupedLAeq();
                    if numel(groupedDistance) == numel(app.FitResult.residuals)
                        noiseanalyzer.writePropagationFitCsv(groupedDistance, groupedLevel, ...
                            app.FitResult, fullfile(outFolder, "propagation_fit.csv"));
                    end
                end
            catch ME
                app.setDone('Export failed.');
                uialert(app.UIFigure, ME.message, 'Export failed');
                return
            end
            app.setDone(sprintf('Exported to %s', outFolder));
            uialert(app.UIFigure, sprintf('Summary CSV + per-microphone time-series CSVs written to:\n%s', ...
                outFolder), 'Export complete', 'Icon', 'success');
        end

        function BrowseOutputButtonPushed(app, ~)
            folder = uigetdir(pwd, 'Select output folder');
            if isequal(folder, 0)
                return
            end
            app.OutputFolderEditField.Value = folder;
        end

        function LoadConfigButtonPushed(app, ~)
            [file, folder] = uigetfile('*.csv', 'Select settings file');
            if isequal(file, 0)
                return
            end
            try
                T = readtable(fullfile(folder, file), 'TextType', 'string');
                if ~all(ismember({'Setting','Value'}, T.Properties.VariableNames))
                    error('CSV must have Setting and Value columns.');
                end
                app.SettingsTable.Data = table(cellstr(T.Setting), cellstr(string(T.Value)), ...
                    'VariableNames', {'Setting','Value'});
            catch ME
                uialert(app.UIFigure, ME.message, 'Failed to load settings');
            end
        end

        function SaveConfigButtonPushed(app, ~)
            [file, folder] = uiputfile('*.csv', 'Save settings as', 'noise_analyzer_settings.csv');
            if isequal(file, 0)
                return
            end
            writetable(app.SettingsTable.Data, fullfile(folder, file));
        end

        function DistanceMetricChanged(app, ~)
            app.plotDistance();
            app.plotResiduals();
        end

        function FitModelButtonPushed(app, ~)
            if app.DistanceMetricDropDown.Value ~= "LAeq"
                uialert(app.UIFigure, ...
                    'Model fitting currently supports the LAeq metric only (it needs an A-weighted level to compare against ISO 9613-2). Switch the Distance Analysis metric to LAeq first.', ...
                    'Cannot fit');
                return
            end
            [groupedDistance, groupedLevel] = app.getGroupedLAeq();
            if numel(groupedDistance) < 2
                uialert(app.UIFigure, ...
                    'Need at least 2 included, analyzed microphones at different distances.', 'Cannot fit');
                return
            end
            s = app.getPropagationSettings();
            targets = string.empty;
            if s.FitLw, targets(end+1) = "Lw"; end
            if s.FitG, targets(end+1) = "G"; end
            if isempty(targets)
                uialert(app.UIFigure, 'Select at least one of Fit Lw / Fit G.', 'Cannot fit');
                return
            end
            app.setBusy('Fitting propagation model...');
            try
                app.FitResult = noiseanalyzer.fitSourceLevelAndGroundFactor(groupedDistance, groupedLevel, ...
                    'TemperatureC', s.TemperatureC, 'RelativeHumidityPct', s.RelativeHumidityPct, ...
                    'PressureKPa', s.PressureKPa, 'hs', s.hs, 'hr', s.hr, 'Dc', s.Dc, ...
                    'FitTargets', targets, 'FixedG', s.FixedG, 'Solver', s.Solver);
            catch ME
                app.setDone('Fit failed.');
                uialert(app.UIFigure, ME.message, 'Fit failed');
                return
            end
            app.setDone('Fit complete.');
            app.refreshFitResultsLabel();
            app.plotDistance();
            app.plotResiduals();
        end

    end

    methods (Access = private)

        function createComponents(app)
            app.UIFigure = uifigure('Name', 'Noise Analyzer', 'Position', [80 60 1300 760], ...
                'Visible', 'off');

            app.GridLayout = uigridlayout(app.UIFigure, [1 2]);
            app.GridLayout.ColumnWidth = {400, '1x'};

            % --- Left control panel ---
            app.ControlPanel = uipanel(app.GridLayout, 'Title', 'Controls');
            app.ControlPanel.Layout.Row = 1;
            app.ControlPanel.Layout.Column = 1;

            app.ControlGrid = uigridlayout(app.ControlPanel, [13 1]);
            app.ControlGrid.RowHeight = {28, 150, 28, 20, 110, 30, 30, 26, 20, 30, 30, 30, '1x'};

            app.AddMicButton = uibutton(app.ControlGrid, 'Text', 'Add Microphone(s)...', ...
                'ButtonPushedFcn', @(~, e) app.AddMicButtonPushed(e));
            app.AddMicButton.Layout.Row = 1;

            app.MicTable = uitable(app.ControlGrid, ...
                'ColumnEditable', [false true true false false], ...
                'CellEditCallback', @(~, e) app.MicTableCellEdit(e), ...
                'CellSelectionCallback', @(~, e) app.MicTableCellSelection(e));
            app.MicTable.Layout.Row = 2;

            app.RemoveMicButton = uibutton(app.ControlGrid, 'Text', 'Remove Selected Microphone', ...
                'ButtonPushedFcn', @(~, e) app.RemoveMicButtonPushed(e));
            app.RemoveMicButton.Layout.Row = 3;

            app.SettingsLabel = uilabel(app.ControlGrid, 'Text', 'Settings:', 'FontWeight', 'bold');
            app.SettingsLabel.Layout.Row = 4;

            defaultSettings = table( ...
                {'SampleRateHz'; 'ReferencePressurePa'; 'TimeWeighting'; 'AggregationMethod'}, ...
                {''; '2e-5'; 'Fast'; 'Mean'}, ...
                'VariableNames', {'Setting', 'Value'});
            app.SettingsTable = uitable(app.ControlGrid, 'Data', defaultSettings, ...
                'ColumnEditable', [false true]);
            app.SettingsTable.Layout.Row = 5;

            app.ConfigButtonGrid = uigridlayout(app.ControlGrid, [1 2]);
            app.ConfigButtonGrid.Layout.Row = 6;
            app.ConfigButtonGrid.Padding = [0 0 0 0];
            app.LoadConfigButton = uibutton(app.ConfigButtonGrid, 'Text', 'Load config (csv)...', ...
                'ButtonPushedFcn', @(~, e) app.LoadConfigButtonPushed(e));
            app.SaveConfigButton = uibutton(app.ConfigButtonGrid, 'Text', 'Save config (csv)...', ...
                'ButtonPushedFcn', @(~, e) app.SaveConfigButtonPushed(e));

            app.AnalyzeAllButton = uibutton(app.ControlGrid, 'Text', 'Analyze All', ...
                'BackgroundColor', [0.2 0.6 0.3], 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~, e) app.AnalyzeAllButtonPushed(e));
            app.AnalyzeAllButton.Layout.Row = 7;

            app.StatusGrid = uigridlayout(app.ControlGrid, [1 2]);
            app.StatusGrid.Layout.Row = 8;
            app.StatusGrid.ColumnWidth = {24, '1x'};
            app.StatusGrid.Padding = [0 0 0 0];
            app.StatusLamp = uilamp(app.StatusGrid, 'Color', [0.2 0.7 0.3]);
            app.StatusLabel = uilabel(app.StatusGrid, 'Text', 'Ready.');

            app.OutputFolderLabel = uilabel(app.ControlGrid, 'Text', 'Output folder:');
            app.OutputFolderLabel.Layout.Row = 9;

            app.OutputFolderGrid = uigridlayout(app.ControlGrid, [1 2]);
            app.OutputFolderGrid.Layout.Row = 10;
            app.OutputFolderGrid.ColumnWidth = {'1x', 70};
            app.OutputFolderGrid.Padding = [0 0 0 0];
            app.OutputFolderEditField = uieditfield(app.OutputFolderGrid, 'text');
            app.BrowseOutputButton = uibutton(app.OutputFolderGrid, 'Text', 'Browse...', ...
                'ButtonPushedFcn', @(~, e) app.BrowseOutputButtonPushed(e));

            app.ExportButton = uibutton(app.ControlGrid, 'Text', 'Export Summary + CSVs', ...
                'ButtonPushedFcn', @(~, e) app.ExportButtonPushed(e));
            app.ExportButton.Layout.Row = 11;

            % --- Right side: plots + summary ---
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 2;

            app.WaveformTab = uitab(app.TabGroup, 'Title', 'Waveform');
            app.WaveformGrid = uigridlayout(app.WaveformTab, [2 1]);
            app.WaveformGrid.RowHeight = {'1x', 40};
            app.WaveformAxes = uiaxes(app.WaveformGrid);
            app.WaveformAxes.Layout.Row = 1;

            app.TrimControlGrid = uigridlayout(app.WaveformGrid, [1 8]);
            app.TrimControlGrid.Layout.Row = 2;
            app.TrimControlGrid.ColumnWidth = {70, 90, 60, 90, 100, 100, 70, 70};
            app.TrimControlGrid.Padding = [0 0 0 0];
            app.TrimStartLabel = uilabel(app.TrimControlGrid, 'Text', 'Start (s):');
            app.TrimStartField = uieditfield(app.TrimControlGrid, 'numeric');
            app.TrimEndLabel = uilabel(app.TrimControlGrid, 'Text', 'End (s):');
            app.TrimEndField = uieditfield(app.TrimControlGrid, 'numeric');
            app.ApplyTrimButton = uibutton(app.TrimControlGrid, 'Text', 'Apply Trim', ...
                'ButtonPushedFcn', @(~, e) app.ApplyTrimButtonPushed(e));
            app.ResetTrimButton = uibutton(app.TrimControlGrid, 'Text', 'Reset Trim', ...
                'ButtonPushedFcn', @(~, e) app.ResetTrimButtonPushed(e));
            app.PlayButton = uibutton(app.TrimControlGrid, 'Text', 'Play', ...
                'ButtonPushedFcn', @(~, e) app.PlayButtonPushed(e));
            app.StopButton = uibutton(app.TrimControlGrid, 'Text', 'Stop', ...
                'ButtonPushedFcn', @(~, e) app.StopButtonPushed(e));

            app.LevelTab = uitab(app.TabGroup, 'Title', 'Level vs Time');
            app.LevelGrid = uigridlayout(app.LevelTab, [1 1]);
            app.LevelAxes = uiaxes(app.LevelGrid);

            app.SpectrumTab = uitab(app.TabGroup, 'Title', 'Spectrum');
            app.SpectrumGrid = uigridlayout(app.SpectrumTab, [1 1]);
            app.SpectrumAxes = uiaxes(app.SpectrumGrid);

            app.DistanceTab = uitab(app.TabGroup, 'Title', 'Distance Analysis');
            app.DistanceGrid = uigridlayout(app.DistanceTab, [4 1]);
            app.DistanceGrid.RowHeight = {30, 190, '1.6x', '0.8x'};
            app.DistanceMetricDropDown = uidropdown(app.DistanceGrid, ...
                'Items', {'LAeq','LCeq','LZeq','LAFmax','LASmax','LA10','LA50','LA90'}, ...
                'Value', 'LAeq', ...
                'ValueChangedFcn', @(~, e) app.DistanceMetricChanged(e));
            app.DistanceMetricDropDown.Layout.Row = 1;

            % --- Propagation model panel: predicts Lp(d) from ISO 9613-2 (geometric spreading +
            % atmospheric absorption + ground effect, noiseanalyzer.predictedSoundPressureLevel)
            % and fits the unknown source power level Lw and/or ground factor G to the measured
            % multi-mic LAeq-vs-distance data (noiseanalyzer.fitSourceLevelAndGroundFactor).
            app.PropagationPanel = uipanel(app.DistanceGrid, 'Title', 'Propagation model (ISO 9613-2)');
            app.PropagationPanel.Layout.Row = 2;
            app.PropagationGrid = uigridlayout(app.PropagationPanel, [5 6]);
            app.PropagationGrid.RowHeight = {26, 26, 26, 30, 40};

            uilabel(app.PropagationGrid, 'Text', 'Temp (C):');
            app.TemperatureField = uieditfield(app.PropagationGrid, 'numeric', 'Value', 15);
            uilabel(app.PropagationGrid, 'Text', 'RH (%):');
            app.HumidityField = uieditfield(app.PropagationGrid, 'numeric', 'Value', 70);
            uilabel(app.PropagationGrid, 'Text', 'Pressure (kPa):');
            app.PressureField = uieditfield(app.PropagationGrid, 'numeric', 'Value', 101.325);

            uilabel(app.PropagationGrid, 'Text', 'Source height hs (m):');
            app.SourceHeightField = uieditfield(app.PropagationGrid, 'numeric', 'Value', 1.5);
            uilabel(app.PropagationGrid, 'Text', 'Receiver height hr (m):');
            app.ReceiverHeightField = uieditfield(app.PropagationGrid, 'numeric', 'Value', 1.5);
            uilabel(app.PropagationGrid, 'Text', 'Ground factor G [0=hard,1=porous]:');
            app.GroundFactorField = uieditfield(app.PropagationGrid, 'numeric', 'Value', 0.5, ...
                'Limits', [0 1]);

            uilabel(app.PropagationGrid, 'Text', 'Directivity Dc (dB, fixed):');
            app.DirectivityField = uieditfield(app.PropagationGrid, 'numeric', 'Value', 0);
            app.FitLwCheckBox = uicheckbox(app.PropagationGrid, 'Text', 'Fit Lw', 'Value', true);
            app.FitGCheckBox = uicheckbox(app.PropagationGrid, 'Text', 'Fit G', 'Value', true);
            uilabel(app.PropagationGrid, 'Text', 'Grouping tolerance (m):');
            app.ToleranceField = uieditfield(app.PropagationGrid, 'numeric', 'Value', 0.5);

            uilabel(app.PropagationGrid, 'Text', 'Solver:');
            app.SolverDropDown = uidropdown(app.PropagationGrid, ...
                'Items', {'lsqnonlin','fminsearch','fmincon','ga','particleswarm'}, 'Value', 'lsqnonlin');
            app.FitModelButton = uibutton(app.PropagationGrid, 'Text', 'Fit Model', ...
                'BackgroundColor', [0.2 0.5 0.7], 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~, e) app.FitModelButtonPushed(e));

            app.FitResultsLabel = uilabel(app.PropagationGrid, 'Text', 'No fit yet.', 'WordWrap', 'on');
            app.FitResultsLabel.Layout.Row = 5;
            app.FitResultsLabel.Layout.Column = [1 6];

            app.DistanceAxes = uiaxes(app.DistanceGrid);
            app.DistanceAxes.Layout.Row = 3;

            app.ResidualsAxes = uiaxes(app.DistanceGrid);
            app.ResidualsAxes.Layout.Row = 4;

            app.SummaryTab = uitab(app.TabGroup, 'Title', 'Summary');
            app.SummaryGrid = uigridlayout(app.SummaryTab, [1 1]);
            app.SummaryTable = uitable(app.SummaryGrid);

            app.refreshMicTable();

            app.UIFigure.Visible = 'on';
        end

    end

    methods (Access = public)

        function app = NoiseAnalyzerApp()
            createComponents(app)
            registerApp(app, app.UIFigure)
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if ~isempty(app.Player) && isvalid(app.Player)
                stop(app.Player);
            end
            delete(app.UIFigure)
        end

    end
end
