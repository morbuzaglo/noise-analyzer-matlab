function AbarCapped = windTurbineBarrierAttenuation(Abar)
%WINDTURBINEBARRIERATTENUATION Cap barrier attenuation for wind-turbine sources at 3 dB, ISO
%   9613-2:2024 Annex D.3: reported cases where the standard 7.4 barrier model didn't match
%   observed screening effects for wind turbines. Recommends capping Abar (for *terrain*
%   screening only -- this annex does not address building screening) at 3 dB, and/or using a
%   source height higher than hub height (e.g. blade-tip height) when computing the barrier
%   geometry passed into barrierAttenuation in the first place.
arguments
    Abar double
end
AbarCapped = min(Abar, 3);
end
