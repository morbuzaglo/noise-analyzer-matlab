function Dwd = windDirectivityDwd(phi, Q, phiWidth)
%WINDDIRECTIVITYDWD Example model for the apparent large-distance directivity when wind blows
%   from direction phi (wind blowing from phi=0 toward the propagation direction), ISO
%   9613-2:2024 Annex C.1 eq.(C.2) -- new in 2024:
%   Dwd(phi) = -Q * {1 - cos[phi - pi - phiWidth*sin(phi-pi)]} dB.
%   Q = half the upwind large-distance attenuation (dB); phiWidth = angle (rad) defining the
%   width of the upwind attenuation window. Standard's preferred/default values: Q=5, phiWidth=
%   pi/4 (both defaulted here). Feeds meteorologicalCorrectionFromWindSamples (eq.C.6).
arguments
    phi double
    Q (1,1) double = 5
    phiWidth (1,1) double = pi/4
end
Dwd = -Q .* (1 - cos(phi - pi - phiWidth.*sin(phi - pi)));
end
