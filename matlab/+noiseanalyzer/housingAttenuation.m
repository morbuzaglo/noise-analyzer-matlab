function Ahous = housingAttenuation(B, db)
%HOUSINGATTENUATION A-weighted attenuation from propagation through a built-up region of houses,
%   ISO 9613-2:2024 Annex A.4 eq.(A.4)-(A.5): Ahous = Ahous,1 (+ Ahous,2), capped at 10 dB.
%   Ahous,1 = 0.1*B*db dB, B = building plan-area density (total house footprint / total ground
%   area, 0-1), db = path length through the built-up region (m, may combine a near-source and
%   near-receiver portion per Figure A.1).
%
%   NOTE: ISO 9613-2:1996 had a second term, Ahous,2 (eq.A.3, for well-defined rows of buildings
%   along a road/rail corridor: Ahous,2 = -10*lg[1-(p/100)], p = % of frontage lined by facades).
%   No equivalent eq. for Ahous,2 was found while transcribing the 2024 Annex A.4 text -- possibly
%   dropped, or on a page not reviewed. This function implements Ahous,1 ONLY; add your own
%   Ahous,2 term if you have a source for its 2024 formula. Per the standard, set Ahous=0 entirely
%   for a small source with a direct, unobstructed sight-line through a corridor gap between
%   housing structures (not automated here -- a geometric judgment call for the caller).
arguments
    B (1,1) double
    db (1,1) double
end
Ahous1 = 0.1 * B * db;
Ahous = min(Ahous1, 10);
end
