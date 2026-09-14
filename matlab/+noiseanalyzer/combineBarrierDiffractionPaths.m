function Abar = combineBarrierDiffractionPaths(AbarTop, AbarSide1, AbarSide2)
%COMBINEBARRIERDIFFRACTIONPATHS Combine top-edge and up to two lateral-diffraction barrier
%   attenuation contributions into the final Abar, ISO 9613-2:2024 eq.(25):
%   Abar = -10*lg(10^(-0.1*AbarTop) + 10^(-0.1*AbarSide1) + 10^(-0.1*AbarSide2)) dB.
%   Pass Inf (the default) for any path that isn't relevant/present, per the standard's own rule
%   that such a path's summand in the bracket must be 0 -- 10^(-0.1*Inf) = 0 achieves that (a
%   path with Abar=0 would instead contribute a full extra unit to the sum and pull the combined
%   Abar down, which is wrong: verified numerically that combining a single real path (AbarTop)
%   with two Inf placeholders reproduces AbarTop exactly, as it must). Result floored at 0.
arguments
    AbarTop double = Inf
    AbarSide1 double = Inf
    AbarSide2 double = Inf
end
Abar = -10*log10(10.^(-0.1*AbarTop) + 10.^(-0.1*AbarSide1) + 10.^(-0.1*AbarSide2));
Abar = max(Abar, 0);
end
