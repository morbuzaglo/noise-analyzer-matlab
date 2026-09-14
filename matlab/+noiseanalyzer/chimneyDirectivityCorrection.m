function Dc = chimneyDirectivityCorrection(theta, ka)
%CHIMNEYDIRECTIVITYCORRECTION Directivity correction Dc for a chimney/vertical-open-pipe source
%   modelled as a point source at the opening, ISO 9613-2:2024 Annex B (new in 2024) Table B.1,
%   bilinearly interpolated over the standard's tabulated (theta, ka) grid, with the extension
%   rules given in Annex B.1:
%     ka < 1            -> Dc = 0
%     1 <= ka <= 4       -> interpolate linearly between (ka=1, Dc=0) and the ka=4 table column
%     ka > 32            -> Dc held constant at the ka=32 column
%     theta < 30 deg     -> Dc held constant at the theta=30 row
%     theta > 120 deg    -> Dc held constant at the theta=120 row
%   theta from chimneyRadiationAngle (eq.B.1, degrees), ka from chimneyKa (eq.B.3). theta=0 is
%   straight up; table only covers the downwind-relevant 30-120 degree range.
%
%   NOTE: the source table's theta=120/ka=6.3 cell reads "-77" in the reviewed PDF -- treated
%   here as a transcription artefact and corrected to -7.7 (consistent with neighbouring values
%   -7.0 at ka=5.0 and -8.2 at ka=8.0). Re-verify against the standard directly if this specific
%   cell matters for your use case.
arguments
    theta double
    ka double
end
kaGrid = [1.0, 4.0, 5.0, 6.3, 8.0, 10.1, 12.7, 16.0, 20.2, 25.4, 32.0];
thetaGrid = [30, 45, 60, 75, 90, 105, 120];

table = [ ...
     0, 2.4,  2.1,  1.9,  2.0,  2.1,  2.6,  3.1,  3.4,  3.4,  3.3; ...
     0, 4.0,  3.4,  3.1,  3.1,  3.4,  4.0,  4.4,  4.6,  4.6,  4.5; ...
     0, 4.0,  3.4,  3.1,  3.1,  3.4,  4.0,  4.4,  4.6,  4.6,  4.5; ...
     0, 2.4,  2.1,  1.9,  2.0,  2.1,  2.6,  3.1,  3.4,  3.4,  3.3; ...
     0,-2.4, -2.2, -2.0, -1.9, -1.9, -1.9, -1.9, -2.1, -2.3, -2.7; ...
     0,-4.3, -4.6, -5.0, -5.4, -5.9, -6.4, -6.9, -7.3, -7.6, -7.9; ...
     0,-6.3, -7.0, -7.7, -8.2, -8.7, -9.1, -9.6,-10.2,-11.0,-12.1  ...
];

thetaClamped = min(max(theta, 30), 120);
kaClamped = max(ka, 1e-9);
kaClamped(kaClamped > 32) = 32;

Dc = interp2(kaGrid, thetaGrid, table, kaClamped, thetaClamped, 'linear');
Dc(ka < 1) = 0;
end
