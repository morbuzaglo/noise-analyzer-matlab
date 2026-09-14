function z = pathLengthDifferenceAlternative(dss, dsr, e, a, d)
%PATHLENGTHDIFFERENCEALTERNATIVE Path-length difference z via the 7.4.2 "alternative method" (for
%   a barrier edge not perpendicular to the source-receiver line in plan view, sloping, bent, or
%   just a single edge), ISO 9613-2:2024 eq.(24): z = sqrt[(dss+dsr+e)^2 + a^2] - d.
%   Here dss/dsr are perpendicular point-to-edge distances in a plane normal to the edge(s)
%   (Figure 10), not ray-path segment lengths, and a is the source-receiver separation component
%   parallel to the barrier edge. This is the formula barrierAttenuation.m uses internally
%   (carried over unchanged from ISO 9613-2:1996 eq.16/17's single/double-diffraction z).
arguments
    dss (1,1) double
    dsr (1,1) double
    e (1,1) double
    a (1,1) double
    d (1,1) double
end
z = sqrt((dss + dsr + e)^2 + a^2) - d;
end
