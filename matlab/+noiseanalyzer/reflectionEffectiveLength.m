function leff = reflectionEffectiveLength(a, betaA, h, betaH)
%REFLECTIONEFFECTIVELENGTH Effective reflecting-surface dimension leff, ISO 9613-2:2024 eq.(27):
%   leff = min(a*cos(betaA), h*cos(betaH)).
%   a/h = horizontal/vertical extension of the reflecting surface (m); betaA/betaH = angle of
%   incidence projected onto the horizontal plane / onto a vertical plane normal to the surface
%   (rad). Feeds reflectionSurfaceSizeCriterion (eq.26).
arguments
    a (1,1) double
    betaA (1,1) double
    h (1,1) double
    betaH (1,1) double
end
leff = min(a*cos(betaA), h*cos(betaH));
end
