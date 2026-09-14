function Asite = industrialSiteAttenuation(freqHz, ds)
%INDUSTRIALSITEATTENUATION Attenuation from propagation through installations at an industrial
%   plant (pipes, valves, structural elements, etc.), ISO 9613-2:2024 Annex A.3 Table A.7
%   (byte-for-byte identical to ISO 9613-2:1996 Table A.2 -- unchanged). Increases linearly with
%   the curved path length ds through the installations, capped at 10 dB. Recommended to be
%   determined by measurement where possible; this is the standard's own fallback estimate.
arguments
    freqHz double
    ds (1,1) double
end
bands = [63, 125, 250, 500, 1000, 2000, 4000, 8000];
perMetre = [0, 0.015, 0.025, 0.025, 0.02, 0.02, 0.015, 0.015];

lookup = min(perMetre * ds, 10);
Asite = arrayfun(@(f) lookup(bands == f), freqHz);
end
