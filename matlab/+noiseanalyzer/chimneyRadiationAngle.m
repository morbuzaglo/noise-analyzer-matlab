function theta = chimneyRadiationAngle(dp, hs, hr, d, r)
%CHIMNEYRADIATIONANGLE Downwind-curved-ray radiation angle theta for the chimney-stack
%   directivity correction, ISO 9613-2:2024 Annex B.1 eq.(B.1): theta=0 is straight up.
%   theta = 180 - atan2(dp, hs-hr) - asin(d/(2*r)) [degrees; the standard's arctan/arcsin are
%   evaluated in a consistent angle convention -- implemented here via atan2/asin in radians then
%   converted to degrees to match Table B.1's degree axis].
%   dp = source-receiver distance projected to the horizontal plane; hs/hr = source/receiver
%   height; d = full 3D source-receiver distance; r = ray curvature radius (5000 m per the
%   standard, default).
arguments
    dp (1,1) double
    hs (1,1) double
    hr (1,1) double
    d (1,1) double
    r (1,1) double = 5000
end
theta = 180 - atan2d(dp, hs-hr) - asind(d/(2*r));
end
