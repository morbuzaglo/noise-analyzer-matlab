function z = pathLengthDifferenceOverTop(dss, dsr, e, d)
%PATHLENGTHDIFFERENCEOVERTOP Path-length difference z for the default/general over-the-top
%   barrier method, ISO 9613-2:2024 eq.(22): z = (dss + dsr + e) - d.
%   Here dss/dsr/e are true 3D ray-path segment lengths along the "rubber-band" polygon
%   constructed source -> edge1 -> edge2 -> ... -> edgeN -> receiver (Figure 9) -- NOT the
%   perpendicular point-to-edge distances used by the alternative method (see
%   pathLengthDifferenceAlternative.m / eq.24, which is what barrierAttenuation.m uses
%   internally). Negative z if the line of sight passes above the barrier top (single edge, e=0).
arguments
    dss (1,1) double
    dsr (1,1) double
    e (1,1) double
    d (1,1) double
end
z = (dss + dsr + e) - d;
end
