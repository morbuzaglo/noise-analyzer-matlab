function [LpA, Lp, terms] = predictedSoundPressureLevel(LwOctave, d, opts)
%PREDICTEDSOUNDPRESSURELEVEL Predicted overall A-weighted SPL at a receiver a distance d from a
%   single point source of known octave-band sound power LwOctave, assembling the ISO 9613-2
%   propagation terms (geometrical divergence, atmospheric absorption, ground effect,
%   meteorological correction) that today only exist as separate building blocks
%   (geometricalDivergence, atmosphericAttenuationCoefficient/atmosphericAttenuation,
%   groundAttenuation/groundAttenuationSimplified, meteorologicalCorrection,
%   pointSourceOctaveBandLevel, aWeightedSoundPressureLevel). No barrier/reflection/misc terms are
%   included here (Abar=Amisc=0) -- pass a precomputed Abar/Amisc offset via opts if needed, or
%   call the lower-level functions directly for a barrier/reflection scenario.
%
%   LwOctave: either a 1xN per-octave-band sound power level (N = numel(opts.Freq)), or a scalar
%   applied to every band (flat-spectrum assumption).
%   d: straight-line source-to-receiver distance, m (used for geometrical divergence).
%
%   Ground path length dp (used by the ground-effect and meteorological-correction terms) is the
%   horizontal (ground-projected) separation, dp = sqrt(max(d^2 - (hs-hr)^2, 0)) -- reduces to
%   dp = d when hs=hr, and is very close to d whenever source/receiver heights are small relative
%   to distance (the usual outdoor-noise case).
%
%   Returns:
%   LpA    - overall predicted A-weighted SPL at the receiver, dB
%   Lp     - 1xN predicted per-octave-band SPL (before A-weighting/energy-summing)
%   terms  - struct with the individual per-band attenuation terms (Adiv, Aatm, Agr, Cmet) plus
%            dp, for diagnostics/plotting.
arguments
    LwOctave (1,:) double
    d (1,1) double
    opts.Freq (1,:) double = noiseanalyzer.iso9613OctaveBands()
    opts.TemperatureC (1,1) double = 15
    opts.RelativeHumidityPct (1,1) double = 70
    opts.PressureKPa (1,1) double = 101.325
    opts.Gs (1,1) double = 0.5
    opts.Gr (1,1) double = 0.5
    opts.Gm (1,1) double = 0.5
    opts.hs (1,1) double = 1.5
    opts.hr (1,1) double = 1.5
    opts.Dc (1,1) double = 0
    opts.Abar (1,1) double = 0
    opts.Amisc (1,1) double = 0
    opts.C0 (1,1) double = 0
    opts.UseSimplifiedGround (1,1) logical = false
    opts.GroundHeightMean (1,1) double = NaN % hm, required if UseSimplifiedGround
end
nBands = numel(opts.Freq);
if isscalar(LwOctave)
    LwOctave = repmat(LwOctave, 1, nBands);
end

dp = sqrt(max(d^2 - (opts.hs - opts.hr)^2, 0));

Adiv = noiseanalyzer.geometricalDivergence(d);

alpha = noiseanalyzer.atmosphericAttenuationCoefficient(opts.Freq, opts.TemperatureC, ...
    opts.RelativeHumidityPct, opts.PressureKPa);
Aatm = noiseanalyzer.atmosphericAttenuation(alpha, d);

if opts.UseSimplifiedGround
    if isnan(opts.GroundHeightMean)
        error('noiseanalyzer:predictedSoundPressureLevel:MissingGroundHeightMean', ...
            'opts.GroundHeightMean (hm) is required when opts.UseSimplifiedGround is true.');
    end
    Agr = repmat(noiseanalyzer.groundAttenuationSimplified(opts.GroundHeightMean, d), 1, nBands);
else
    Agr = noiseanalyzer.groundAttenuation(opts.Freq, opts.Gs, opts.Gr, opts.Gm, opts.hs, opts.hr, dp);
end

Cmet = noiseanalyzer.meteorologicalCorrection(opts.hs, opts.hr, dp, opts.C0);

Lp = noiseanalyzer.pointSourceOctaveBandLevel(LwOctave, opts.Dc, Adiv, Aatm, Agr, opts.Abar, opts.Amisc) - Cmet;
LpA = noiseanalyzer.aWeightedSoundPressureLevel(Lp, opts.Freq);

terms = struct('Adiv', Adiv, 'Aatm', Aatm, 'Agr', Agr, 'Cmet', Cmet, 'dp', dp);
end
