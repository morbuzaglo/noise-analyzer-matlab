function Gcapped = windTurbineGroundFactor(G)
%WINDTURBINEGROUNDFACTOR Cap the ground factor for wind-turbine sources, ISO 9613-2:2024
%   Annex D.4: comparisons of measured vs. calculated levels show the base 7.3.1 classification
%   (G=1 for porous ground) under-predicts wind-turbine noise and "should therefore not be
%   applied" -- porous/mixed ground should be capped at G=0.5 (hard ground G=0 is unchanged).
%   When G=0.5 is used, the annex also recommends a minimum receiver height of 4 m regardless of
%   actual height (not applied here -- apply hr=max(hr,4) yourself where relevant).
arguments
    G double
end
Gcapped = min(G, 0.5);
end
