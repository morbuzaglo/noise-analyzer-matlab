classdef NoiseAnalyzerApp < matlab.apps.AppBase
    %NOISEANALYZERAPP Interactive app for analyzing a raw sound-pressure recording (Pa vs s):
    %   load data, configure settings (in-app text area or a loadable/savable .txt config file),
    %   compute A-weighted level and related standard metrics, view plots, and export a report
    %   (.txt) plus time-series and summary CSV files. All computation is delegated to the
    %   noiseanalyzer.* functions (analyzeRecording, octaveBandSpectrumFFT, etc.) -- this class
    %   is a thin UI wrapper, not where the acoustics logic lives.
    %
    %   Written as a uifigure-based classdef app (App Designer's own underlying format) rather
    %   than a packaged .mlapp binary, so it stays readable/diffable in source control. Run it
    %   with: app = NoiseAnalyzerApp

    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        GridLayout                 matlab.ui.container.GridLayout
        ControlPanel                matlab.ui.container.Panel
        ControlGrid                 matlab.ui.container.GridLayout
        LoadDataButton               matlab.ui.control.Button
        FilePathLabel                matlab.ui.control.Label
        SettingsLabel                matlab.ui.control.Label
        SettingsTextArea             matlab.ui.control.TextArea
        ConfigButtonGrid             matlab.ui.container.GridLayout
        LoadConfigButton              matlab.ui.control.Button
        SaveConfigButton              matlab.ui.control.Button
        AnalyzeButton                matlab.ui.control.Button
        OutputFolderLabel            matlab.ui.control.Label
        OutputFolderGrid             matlab.ui.container.GridLayout
        OutputFolderEditField         matlab.ui.control.EditField
        BrowseOutputButton            matlab.ui.control.Button
        ExportButton                 matlab.ui.control.Button
        StatusLabel                  matlab.ui.control.Label
        TabGroup                    matlab.ui.container.TabGroup
        WaveformTab                  matlab.ui.container.Tab
        WaveformAxes                  matlab.ui.control.UIAxes
        LevelTab                     matlab.ui.container.Tab
        LevelAxes                     matlab.ui.control.UIAxes
        SpectrumTab                  matlab.ui.container.Tab
        SpectrumAxes                   matlab.ui.control.UIAxes
        SummaryTab                   matlab.ui.container.Tab
        SummaryTable                   matlab.ui.control.Table
    end

    properties (Access = private)
        RawTime double = []
        RawPressure double = []
        Fs double = NaN
        SourceFilePath string = ""
        Results struct = struct()
    end

    methods (Access = private)

        function settings = getParsedSettings(app)
            text = strjoin(app.SettingsTextArea.Value, newline);
            settings = noiseanalyzer.parseSettingsText(string(text));
        end

        function fs = getFallbackSampleRate(app)
            settings = app.getParsedSettings();
            fs = NaN;
            if isfield(settings, 'SampleRateHz') && strlength(settings.SampleRateHz) > 0
                val = str2double(settings.SampleRateHz);
                if ~isnan(val) && val > 0
                    fs = val;
                end
            end
        end

        function p0 = getReferencePressure(app)
            settings = app.getParsedSettings();
            p0 = noiseanalyzer.referencePressure();
            if isfield(settings, 'ReferencePressurePa') && strlength(settings.ReferencePressurePa) > 0
                val = str2double(settings.ReferencePressurePa);
                if ~isnan(val) && val > 0
                    p0 = val;
                end
            end
        end

        function tw = getTimeWeighting(app)
            settings = app.getParsedSettings();
            tw = "Fast";
            if isfield(settings, 'TimeWeighting') && strlength(settings.TimeWeighting) > 0
                if lower(settings.TimeWeighting) == "slow"
                    tw = "Slow";
                end
            end
        end

        function plotWaveform(app)
            cla(app.WaveformAxes);
            if isempty(app.RawPressure)
                return
            end
            plot(app.WaveformAxes, app.RawTime, app.RawPressure, 'Color', [0.2 0.4 0.7]);
            xlabel(app.WaveformAxes, 'Time (s)');
            ylabel(app.WaveformAxes, 'Pressure (Pa)');
            title(app.WaveformAxes, 'Raw signal');
            grid(app.WaveformAxes, 'on');
        end

        function plotLevel(app)
            cla(app.LevelAxes);
            if ~isfield(app.Results, 'tFast')
                return
            end
            if app.getTimeWeighting() == "Slow"
                t = app.Results.tSlow; lvl = app.Results.LpASlow; lbl = 'L_{A,Slow} (dB)';
            else
                t = app.Results.tFast; lvl = app.Results.LpAFast; lbl = 'L_{A,Fast} (dB)';
            end
            plot(app.LevelAxes, t, lvl, 'Color', [0.75 0.2 0.2]);
            xlabel(app.LevelAxes, 'Time (s)');
            ylabel(app.LevelAxes, lbl);
            title(app.LevelAxes, 'A-weighted time-weighted level');
            grid(app.LevelAxes, 'on');
        end

        function plotSpectrum(app)
            cla(app.SpectrumAxes);
            if ~isfield(app.Results, 'octaveBands')
                return
            end
            labels = string(app.Results.octaveBands) + " Hz";
            cats = categorical(labels, labels); % preserve ascending-frequency order
            bar(app.SpectrumAxes, cats, app.Results.octaveLevels, 'FaceColor', [0.3 0.6 0.4]);
            xlabel(app.SpectrumAxes, 'Octave band');
            ylabel(app.SpectrumAxes, 'Level (dB)');
            title(app.SpectrumAxes, 'Octave-band spectrum (FFT estimate)');
            grid(app.SpectrumAxes, 'on');
        end

        function updateSummaryTable(app)
            if ~isfield(app.Results, 'LAeq')
                app.SummaryTable.Data = {};
                return
            end
            r = app.Results;
            metrics = {'LAeq (dB)'; 'LCeq (dB)'; 'LZeq (dB)'; 'LAFmax (dB)'; 'LASmax (dB)'; ...
                'LA10 (dB)'; 'LA50 (dB)'; 'LA90 (dB)'; 'Duration (s)'; 'Sample rate (Hz)'};
            values = [r.LAeq; r.LCeq; r.LZeq; r.LAFmax; r.LASmax; r.LA10; r.LA50; r.LA90; ...
                r.duration; r.fs];
            app.SummaryTable.Data = table(metrics, values, 'VariableNames', {'Metric', 'Value'});
        end

    end

    methods (Access = private)

        function LoadDataButtonPushed(app, ~)
            [file, folder] = uigetfile({'*.csv;*.txt;*.mat', 'Sound data (*.csv, *.txt, *.mat)'}, ...
                'Select sound data file');
            if isequal(file, 0)
                return
            end
            fullPath = fullfile(folder, file);
            fallbackFs = app.getFallbackSampleRate();
            try
                [t, p, fs] = noiseanalyzer.loadPressureTimeData(fullPath, fallbackFs);
            catch ME
                uialert(app.UIFigure, ME.message, 'Failed to load data');
                return
            end
            app.RawTime = t;
            app.RawPressure = p;
            app.Fs = fs;
            app.SourceFilePath = string(fullPath);
            app.Results = struct();
            app.FilePathLabel.Text = sprintf('%s  (%.0f Hz, %.2f s)', file, fs, numel(p)/fs);
            app.StatusLabel.Text = 'Data loaded. Click Analyze.';
            app.plotWaveform();
            app.plotLevel();
            app.plotSpectrum();
            app.updateSummaryTable();
        end

        function AnalyzeButtonPushed(app, ~)
            if isempty(app.RawPressure)
                uialert(app.UIFigure, 'Load a data file first.', 'No data');
                return
            end
            p0 = app.getReferencePressure();
            try
                results = noiseanalyzer.analyzeRecording(app.RawPressure, app.Fs, p0);
                bands = noiseanalyzer.iso9613OctaveBands();
                results.octaveBands = bands;
                results.octaveLevels = noiseanalyzer.octaveBandSpectrumFFT(app.RawPressure, app.Fs, bands, p0);
            catch ME
                uialert(app.UIFigure, ME.message, 'Analysis failed');
                return
            end
            app.Results = results;
            app.StatusLabel.Text = 'Analysis complete.';
            app.plotLevel();
            app.plotSpectrum();
            app.updateSummaryTable();
        end

        function ExportButtonPushed(app, ~)
            if ~isfield(app.Results, 'LAeq')
                uialert(app.UIFigure, 'Run Analyze first.', 'Nothing to export');
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
            if app.SourceFilePath ~= ""
                [~, baseName] = fileparts(app.SourceFilePath);
            else
                baseName = "analysis";
            end
            try
                noiseanalyzer.writeAnalysisReport(app.Results, ...
                    fullfile(outFolder, baseName + "_report.txt"), app.SourceFilePath);
                noiseanalyzer.writeAnalysisCsv(app.Results, ...
                    fullfile(outFolder, baseName + "_timeseries.csv"));
                noiseanalyzer.writeSummaryCsv(app.Results, ...
                    fullfile(outFolder, baseName + "_summary.csv"));
            catch ME
                uialert(app.UIFigure, ME.message, 'Export failed');
                return
            end
            app.StatusLabel.Text = sprintf('Exported to %s', outFolder);
            uialert(app.UIFigure, sprintf('Report, time-series CSV, and summary CSV written to:\n%s', outFolder), ...
                'Export complete', 'Icon', 'success');
        end

        function LoadConfigButtonPushed(app, ~)
            [file, folder] = uigetfile('*.txt', 'Select settings file');
            if isequal(file, 0)
                return
            end
            text = fileread(fullfile(folder, file));
            app.SettingsTextArea.Value = cellstr(splitlines(string(text)));
        end

        function SaveConfigButtonPushed(app, ~)
            [file, folder] = uiputfile('*.txt', 'Save settings as', 'noise_analyzer_settings.txt');
            if isequal(file, 0)
                return
            end
            text = strjoin(app.SettingsTextArea.Value, newline);
            fid = fopen(fullfile(folder, file), 'w');
            fprintf(fid, '%s', text);
            fclose(fid);
        end

        function BrowseOutputButtonPushed(app, ~)
            folder = uigetdir(pwd, 'Select output folder');
            if isequal(folder, 0)
                return
            end
            app.OutputFolderEditField.Value = folder;
        end

    end

    methods (Access = private)

        function createComponents(app)
            app.UIFigure = uifigure('Name', 'Noise Analyzer', 'Position', [100 100 1150 700], ...
                'Visible', 'off');

            app.GridLayout = uigridlayout(app.UIFigure, [1 2]);
            app.GridLayout.ColumnWidth = {340, '1x'};

            % --- Left control panel ---
            app.ControlPanel = uipanel(app.GridLayout, 'Title', 'Controls');
            app.ControlPanel.Layout.Row = 1;
            app.ControlPanel.Layout.Column = 1;

            app.ControlGrid = uigridlayout(app.ControlPanel, [11 1]);
            app.ControlGrid.RowHeight = {30, 22, 20, 160, 30, 30, 20, 30, 30, 30, '1x'};

            app.LoadDataButton = uibutton(app.ControlGrid, 'Text', 'Load Data...', ...
                'ButtonPushedFcn', @(~, e) app.LoadDataButtonPushed(e));
            app.LoadDataButton.Layout.Row = 1;

            app.FilePathLabel = uilabel(app.ControlGrid, 'Text', 'No file loaded', ...
                'FontColor', [0.4 0.4 0.4]);
            app.FilePathLabel.Layout.Row = 2;

            app.SettingsLabel = uilabel(app.ControlGrid, 'Text', 'Settings (key = value):', ...
                'FontWeight', 'bold');
            app.SettingsLabel.Layout.Row = 3;

            app.SettingsTextArea = uitextarea(app.ControlGrid, ...
                'Value', cellstr(splitlines(string(noiseanalyzer.defaultSettingsText()))));
            app.SettingsTextArea.Layout.Row = 4;

            app.ConfigButtonGrid = uigridlayout(app.ControlGrid, [1 2]);
            app.ConfigButtonGrid.Layout.Row = 5;
            app.ConfigButtonGrid.Padding = [0 0 0 0];
            app.LoadConfigButton = uibutton(app.ConfigButtonGrid, 'Text', 'Load config...', ...
                'ButtonPushedFcn', @(~, e) app.LoadConfigButtonPushed(e));
            app.SaveConfigButton = uibutton(app.ConfigButtonGrid, 'Text', 'Save config...', ...
                'ButtonPushedFcn', @(~, e) app.SaveConfigButtonPushed(e));

            app.AnalyzeButton = uibutton(app.ControlGrid, 'Text', 'Analyze', ...
                'BackgroundColor', [0.2 0.6 0.3], 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~, e) app.AnalyzeButtonPushed(e));
            app.AnalyzeButton.Layout.Row = 6;

            app.OutputFolderLabel = uilabel(app.ControlGrid, 'Text', 'Output folder:');
            app.OutputFolderLabel.Layout.Row = 7;

            app.OutputFolderGrid = uigridlayout(app.ControlGrid, [1 2]);
            app.OutputFolderGrid.Layout.Row = 8;
            app.OutputFolderGrid.ColumnWidth = {'1x', 70};
            app.OutputFolderGrid.Padding = [0 0 0 0];
            app.OutputFolderEditField = uieditfield(app.OutputFolderGrid, 'text');
            app.BrowseOutputButton = uibutton(app.OutputFolderGrid, 'Text', 'Browse...', ...
                'ButtonPushedFcn', @(~, e) app.BrowseOutputButtonPushed(e));

            app.ExportButton = uibutton(app.ControlGrid, 'Text', 'Export Report + CSV', ...
                'ButtonPushedFcn', @(~, e) app.ExportButtonPushed(e));
            app.ExportButton.Layout.Row = 9;

            app.StatusLabel = uilabel(app.ControlGrid, 'Text', 'Ready.', 'FontColor', [0.3 0.3 0.3]);
            app.StatusLabel.Layout.Row = 10;

            % --- Right side: plots + summary ---
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 2;

            app.WaveformTab = uitab(app.TabGroup, 'Title', 'Waveform');
            waveformGrid = uigridlayout(app.WaveformTab, [1 1]);
            app.WaveformAxes = uiaxes(waveformGrid);

            app.LevelTab = uitab(app.TabGroup, 'Title', 'Level vs Time');
            levelGrid = uigridlayout(app.LevelTab, [1 1]);
            app.LevelAxes = uiaxes(levelGrid);

            app.SpectrumTab = uitab(app.TabGroup, 'Title', 'Spectrum');
            spectrumGrid = uigridlayout(app.SpectrumTab, [1 1]);
            app.SpectrumAxes = uiaxes(spectrumGrid);

            app.SummaryTab = uitab(app.TabGroup, 'Title', 'Summary');
            summaryGrid = uigridlayout(app.SummaryTab, [1 1]);
            app.SummaryTable = uitable(summaryGrid);

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
            delete(app.UIFigure)
        end

    end
end
