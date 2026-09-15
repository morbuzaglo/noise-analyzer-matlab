%% Noise Analyzer -- Physics, Equations, and Source-Power Fitting Guide
% This script is the source for an interactive MATLAB Live Script (convert via
% Live Editor > Save As > Live Script, or |File > Export| in a live-scripted
% session -- kept as a plain, diffable |.m| file with |%%| cell breaks here so it
% stays readable/reviewable in source control, matching the rest of this
% project's convention of hand-authoring everything as plain text).
%
% Every number below is produced by calling the *actual* |noiseanalyzer.*|
% functions this app uses, not by re-deriving the physics separately -- so this
% document can never silently drift out of sync with the code.
%
% Run this cell-by-cell (Ctrl+Enter) in MATLAB, or run the whole file, from the
% project root with |matlab/| on the path:
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'matlab'));

%% 1. Scope
% This guide covers:
%
% # Sound pressure level (SPL) fundamentals and A-weighting (ISO 1683, IEC 61672-1)
% # Outdoor sound propagation per *ISO 9613-2:2024* -- geometrical divergence,
%   atmospheric absorption, ground effect, meteorological correction
% # The two things that were *missing* before this update: inverting a measured
%   level back to a source sound power level, and assembling the individual
%   attenuation terms into one forward "predicted level at distance" model
% # Fitting an unknown source power level and/or ground hardness to real
%   multi-microphone data by nonlinear optimization
% # Validation: reproducing the project's own worked example, a synthetic
%   ground-truth recovery test, and literature-sourced case studies
%   (|reference/literature_case_studies.md|)

%% 2. SPL fundamentals
% Sound pressure level is defined relative to a reference pressure
% $p_0 = 20\,\mu\mathrm{Pa}$ (the nominal threshold of human hearing at 1 kHz),
% ISO 1683:2015 / ISO/TR 25417:2007:
%
% $$L_p = 20\log_{10}\left(\frac{p}{p_0}\right) \;\mathrm{dB}$$
p0 = noiseanalyzer.referencePressure();
fprintf('Reference pressure p0 = %.3g Pa\n', p0);

% A pure tone at exactly the reference pressure is, by definition, 0 dB; a
% signal at 10x the reference pressure is 20 dB (not 10x the *level*, since dB
% is a logarithmic ratio):
noiseanalyzer.soundPressureLevel(p0)      % -> 0 dB
noiseanalyzer.soundPressureLevel(10*p0)   % -> 20 dB

%% 3. A-weighting
% Human hearing is not equally sensitive at all frequencies, so environmental
% noise levels are almost always reported "A-weighted" (dB(A)): each
% frequency band is boosted or attenuated per a standard curve (IEC 61672-1
% Annex E) before combining. The curve is a fixed analytical function of
% frequency (poles at 20.6/107.7/737.9/12194 Hz, normalized to 0 dB at 1 kHz):
bands = noiseanalyzer.iso9613OctaveBands();  % [63 125 250 500 1000 2000 4000 8000] Hz
Af = noiseanalyzer.weightingFunctionA(bands);
figure; semilogx(bands, Af, 'o-'); grid on;
xlabel('Frequency (Hz)'); ylabel('A-weighting (dB)');
title('IEC 61672-1 A-weighting curve at ISO 9613-2''s octave bands');
% Low frequencies are strongly de-emphasized (Af(63 Hz) is large and negative)
% -- this matters later because it means a source's *spectral shape* affects
% how its overall dB(A) level relates to its per-band sound power.

%% 4. Outdoor sound propagation (ISO 9613-2:2024)
% ISO 9613-2 predicts the octave-band SPL at a receiver from a point source's
% octave-band sound power level $L_W$ (eq. 3-4):
%
% $$L_p = L_W + D_c - A, \qquad A = A_{div} + A_{atm} + A_{gr} + A_{bar} + A_{misc}$$
%
% where $D_c$ is a directivity correction and each $A_x$ term is an
% independent attenuation mechanism, covered one at a time below.

%% 4.1 Geometrical divergence ($A_{div}$)
% Spherical spreading from a point source, eq.(7): every doubling of distance
% loses 6 dB (the classic inverse-square law in dB form).
d = logspace(0, 3, 50);
Adiv = noiseanalyzer.geometricalDivergence(d);
figure; semilogx(d, Adiv); grid on;
xlabel('Distance (m)'); ylabel('A_{div} (dB)');
title('Geometrical divergence: 20log_{10}(d) + 11');

%% 4.2 Atmospheric absorption ($A_{atm}$)
% Air itself absorbs sound, increasingly at high frequency, with a
% temperature- and humidity-dependent coefficient (ISO 9613-1:1993 analytical
% formula). This reproduces the standard's own Table 2 values:
weatherConditions = {
    struct('T', 20, 'RH', 70, 'label', '20{\circ}C, 70% RH')
    struct('T', 10, 'RH', 70, 'label', '10{\circ}C, 70% RH')
    struct('T', 15, 'RH', 20, 'label', '15{\circ}C, 20% RH')
};
figure; hold on;
for i = 1:numel(weatherConditions)
    w = weatherConditions{i};
    alpha = noiseanalyzer.atmosphericAttenuationCoefficient(bands, w.T, w.RH);
    semilogx(bands, alpha, 'o-', 'DisplayName', w.label);
end
hold off; grid on; legend('Location', 'best');
xlabel('Frequency (Hz)'); ylabel('\alpha (dB/km)');
title('Atmospheric attenuation coefficient (ISO 9613-1)');
% Over a fixed distance, Aatm = alpha * d / 1000:
alpha1kHz = noiseanalyzer.atmosphericAttenuationCoefficient(1000, 20, 70);
noiseanalyzer.atmosphericAttenuation(alpha1kHz, 500) % dB lost to air absorption at 1 kHz over 500 m

%% 4.3 Ground effect ($A_{gr}$)
% Reflections off the ground between source and receiver interfere with the
% direct sound, and porous ("soft", absorptive) ground attenuates more than
% hard ground. The ground factor $G$ ranges from 0 (hard: concrete, water) to
% 1 (porous: grass, snow, farmland) -- this is exactly the "how soft or hard
% is the ground" parameter this update lets you *fit* from data instead of
% guessing.
figure; hold on;
for G = [0 0.3 0.5 0.7 1.0]
    Agr = noiseanalyzer.groundAttenuation(bands, G, G, G, 1.5, 1.5, 100);
    semilogx(bands, Agr, 'o-', 'DisplayName', sprintf('G = %.1f', G));
end
hold off; grid on; legend('Location', 'best');
xlabel('Frequency (Hz)'); ylabel('A_{gr} (dB)');
title('Ground attenuation vs. ground factor G, d_p=100m, h_s=h_r=1.5m');
% Hard ground (G=0) gives a flat -3 dB (a well-known result: perfectly
% reflective ground doubles the pressure at low frequency but the standard
% caps it at -3dB flat across bands); porous ground gives much larger,
% frequency-dependent attenuation, especially at low-to-mid frequencies.

%% 4.4 Meteorological correction ($C_{met}$)
% Wind and temperature gradients bend sound rays. For long-term-average
% predictions (not a single downwind gust), a correction $C_{met}$ softens the
% predicted level at long range (eq. 31-32):
dpRange = linspace(1, 2000, 200);
Cmet = arrayfun(@(dp) noiseanalyzer.meteorologicalCorrection(1.5, 1.5, dp, 2), dpRange);
figure; plot(dpRange, Cmet); grid on;
xlabel('Path length d_p (m)'); ylabel('C_{met} (dB)');
title('Meteorological correction, C_0=2 dB (typical long-term average)');

%% 4.5 Putting it together: the forward model
% Before this update, calling all of the above and assembling them into one
% receiver-level prediction had to be done by hand, one line per term (see the
% project's own |README.md| "Usage" example). |predictedSoundPressureLevel| is
% the new orchestrating function that does this in one call, given raw
% physical inputs instead of pre-computed attenuation terms:
Lw = 100 * ones(1, numel(bands)); % 100 dB source power, flat spectrum, all bands
[LpA, LpBands, terms] = noiseanalyzer.predictedSoundPressureLevel(Lw, 100, ...
    'TemperatureC', 20, 'RelativeHumidityPct', 70, 'Gs', 0, 'Gr', 0, 'Gm', 0, ...
    'hs', 4, 'hr', 1.5);
fprintf('Predicted overall level at 100 m: %.2f dB(A)\n', LpA);
% This should read 57.34 dB -- the project's own already-verified worked
% example (README.md / CLAUDE.md), now produced by a single function call
% instead of five.
disp(terms);

% Sweeping distance gives the full attenuation curve:
distances = logspace(0, 3, 60);
levels = arrayfun(@(dd) noiseanalyzer.predictedSoundPressureLevel(Lw, dd, ...
    'TemperatureC', 20, 'RelativeHumidityPct', 70, 'Gs', 0.5, 'Gr', 0.5, 'Gm', 0.5, ...
    'hs', 4, 'hr', 1.5), distances);
figure; semilogx(distances, levels); grid on;
xlabel('Distance (m)'); ylabel('Predicted L_{Aeq} (dB)');
title('Predicted level vs. distance, G=0.5, 20{\circ}C/70%RH');

%% 5. Inverting a measurement: what source power produced this level?
% If you *know* a receiver's measured level and the propagation conditions,
% the forward relationship $L_p = L_W + D_c - A$ is linear in $L_W$, so it
% inverts trivially:
%
% $$L_W = L_p - D_c + A$$
%
% |invertSourcePowerLevel| does exactly this -- the algebraic mirror of
% |pointSourceOctaveBandLevel| that didn't exist before:
Adiv100 = noiseanalyzer.geometricalDivergence(100);
measuredLp = 69; % e.g. one measured octave-band SPL, dB
LwBack = noiseanalyzer.invertSourcePowerLevel(measuredLp, 0, Adiv100);
fprintf('A %.0f dB measurement at 100m (divergence only) implies Lw = %.1f dB\n', measuredLp, LwBack);
% For a real spectrum, pass the matching Aatm/Agr/Abar/Amisc terms too:
% LwBack = invertSourcePowerLevel(measuredLp, Dc, Adiv, Aatm, Agr, Abar, Amisc)

% In practice, though, this app only ever measures an *overall* dB(A) value
% (LAeq), not a calibrated per-band spectrum. |estimateSourcePowerLevelFromMeasurement|
% handles that case: given an assumed *relative* spectral shape (flat by
% default), the A-weighted combination is a log-sum-exp that factors linearly
% in the unknown overall level, so the inversion is still exact, not a fit:
LwEstimate = noiseanalyzer.estimateSourcePowerLevelFromMeasurement(57.34, zeros(1,numel(bands)), 0, Adiv100, ...
    noiseanalyzer.atmosphericAttenuation(noiseanalyzer.atmosphericAttenuationCoefficient(bands,20,70), 100), ...
    noiseanalyzer.groundAttenuation(bands, 0,0,0, 4, 1.5, 100));
fprintf('Estimated Lw from a single 57.34 dB(A) measurement at 100m: %.2f dB\n', LwEstimate);
% (should recover ~100 dB, the Lw used to generate that 57.34 dB reading above)

%% 6. Fitting unknown parameters to real multi-microphone data
% Section 5's inversion needs the ground factor G (and everything else) to
% already be *known*. In a real experiment you typically only *guess* G (or
% don't know it at all) -- but if you have microphones at several distances,
% you can instead solve for the $(L_W, G)$ pair that makes the ISO 9613-2
% curve best match what was actually measured. This is a nonlinear
% least-squares problem (the ground-effect term is nonlinear in both G and
% distance), solved here with |lsqnonlin| (falling back to the toolbox-free
% |fminsearch| automatically if Optimization Toolbox isn't licensed).
%
% Since no real experimental dataset exists yet, this section demonstrates
% the fit against *synthetic* data with a *known* ground truth
% (|simulateMultiMicMeasurement|) -- the fit either recovers the known answer
% or it doesn't, which is a much stronger check than "it runs".
trueLw = 105; trueG = 0.65;
micDistances = [10; 20; 40; 80; 160];
[~, measuredLevels] = noiseanalyzer.simulateMultiMicMeasurement(trueLw, micDistances, ...
    'Gs', trueG, 'Gr', trueG, 'Gm', trueG, 'NoiseStdDb', 0.5, 'Seed', 1);

fitResult = noiseanalyzer.fitSourceLevelAndGroundFactor(micDistances, measuredLevels);
fprintf('True Lw=%.1f, G=%.2f  |  Fitted Lw=%.1f, G=%.2f  (RMSE=%.2f dB, R^2=%.3f, solver=%s)\n', ...
    trueLw, trueG, fitResult.LwFit, fitResult.GFit, fitResult.RMSE, fitResult.R2, fitResult.solverUsed);

figure; hold on;
scatter(micDistances, measuredLevels, 60, 'filled', 'DisplayName', 'Synthetic "measured" data');
plot(fitResult.predictedCurve.Distance, fitResult.predictedCurve.Level, 'LineWidth', 1.5, ...
    'DisplayName', 'Fitted ISO 9613-2 model');
hold off; grid on; legend('Location', 'best');
xlabel('Distance (m)'); ylabel('L_{Aeq} (dB)');
title(sprintf('Recovered Lw=%.1f dB, G=%.2f (true: %.1f dB, %.2f)', ...
    fitResult.LwFit, fitResult.GFit, trueLw, trueG));

%% 6.1 Solver comparison
% Different solvers trade off speed, robustness to local minima, and toolbox
% requirements. For this well-behaved 2-parameter problem they should all
% agree closely; |ga|/|particleswarm| matter more for harder, more
% multi-parameter fits (e.g. jointly fitting separate Gs/Gr/Gm) where a local
% solver could get stuck.
solvers = ["lsqnonlin", "fminsearch"];
if license('test', 'GADS_Toolbox')
    solvers = [solvers, "particleswarm"];
end
for s = solvers
    r = noiseanalyzer.fitSourceLevelAndGroundFactor(micDistances, measuredLevels, 'Solver', s);
    fprintf('%-14s: Lw=%.2f  G=%.3f  RMSE=%.3f\n', s, r.LwFit, r.GFit, r.RMSE);
end

%% 7. Validation and literature comparison
% Beyond the synthetic recovery test above, |tests/FitSourceLevelAndGroundFactorTest.m|
% (matlab.unittest) runs this same recovery check as an automated regression
% test across several true (Lw, G) combinations and solvers, and
% |tests/PredictedSoundPressureLevelTest.m| pins the forward model to the
% project's own already-verified 57.34 dB worked example.
%
% For grounding against the outside world (not just internal consistency),
% see |reference/literature_case_studies.md|: published outdoor sound
% propagation data (regulatory filings, field studies, textbook examples)
% compared against this model's predictions, with reported error in dB
% relative to ISO 9613-2's own claimed +/-3 dB engineering-method accuracy.

%% 8. Practical usage and limitations
% * The Distance Analysis tab in |app/NoiseAnalyzerApp.m| exposes all of this
%   interactively: set temperature/humidity/pressure/heights, choose which of
%   Lw/G to fit (or fix), pick a solver, and click *Fit Model* -- it groups
%   your included, analyzed microphones by distance
%   (|groupLevelsByDistance|), runs the fit, and overlays the fitted curve
%   plus a residuals plot on the measured data.
% * Fitting currently works on the overall LAeq metric only, with a
%   *flat-spectrum* assumption by default (pass a real relative octave-band
%   shape via |SpectrumShapeDb| if you have one) -- per-band fitting would
%   need a calibrated octave-band spectrum, which the app's current
%   FFT-based spectrum estimate is explicitly documented as not providing.
% * Directivity ($D_c$) and long-term meteorological correction ($C_0$) are
%   fixed inputs, not fit targets -- a single-azimuth, snapshot-in-time
%   dataset can't identify either one.
% * A single lumped ground factor $G$ (applied to source, receiver, and
%   middle regions alike) is fit by default; call
%   |fitSourceLevelAndGroundFactor|'s underlying |predictedSoundPressureLevel|
%   directly with separate Gs/Gr/Gm if your terrain genuinely differs by
%   region -- exposing that as a UI toggle is a reasonable future addition,
%   flagged in the project roadmap, not built here to avoid overfitting a
%   typically-sparse multi-radius dataset with too many free parameters.
% * No barrier, reflection, or foliage/industrial/housing terms are included
%   in |predictedSoundPressureLevel| by default (Abar=Amisc=0) -- pass them
%   in via the lower-level functions directly for a scenario where they
%   matter (e.g. a building or noise wall between source and receiver).
