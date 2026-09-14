function Abar = barrierAttenuation(freqHz, dss, dsr, a, d, e, Agr, C2)
%BARRIERATTENUATION Barrier (screening) insertion loss, ISO 9613-2:2024 eqs.(16)-(21).
%
%   For diffraction over the top edge when Agr > 0 (downwind), returns Abar = Dz - Agr per
%   eq.(16). For lateral (vertical-edge) diffraction, OR whenever Agr <= 0, returns Abar = Dz per
%   eq.(17) (pass Agr = 0, the default, for a pure lateral-diffraction path).
%
%   e = 0 (default) selects single diffraction (one edge, C3 = 1); e > 0 selects diffraction
%   around/over multiple edges (e = total ray-path length between the first diffracting edge
%   behind the source and the last in front of the receiver, per the standard's generalization of
%   "double diffraction" to any number of edges). dss, dsr, a, d, e are geometry and do not depend
%   on octave band; freqHz may be a vector of bands.
%
%   Supersedes ISO 9613-2:1996 eqs.(12)-(18): the Dz formula itself changed (not just relabeled),
%   most importantly adding a minimum-path-difference floor zmin below which Dz=0 outright
%   (eq.19), and reworking the Kmet meteorological-correction formula (eq.21) to generalize
%   beyond two edges. See reference/iso_9613_2_2024_notes.md for the eq.-by-eq. comparison.
%
%   Not implemented: the 1996 edition capped Dz at 20 dB (single diffraction) / 25 dB (double
%   diffraction); whether the 2024 edition kept an equivalent cap (likely in 7.4.4, "combining
%   vertical and lateral diffractions and limitations") was not confirmed while transcribing this
%   -- no cap is applied here. Check the standard directly before relying on this for very large
%   barrier attenuations.
arguments
    freqHz double
    dss (1,1) double
    dsr (1,1) double
    a (1,1) double
    d (1,1) double
    e (1,1) double = 0
    Agr double = 0
    C2 (1,1) double = 20
end
if e == 0
    z = sqrt((dss + dsr)^2 + a^2) - d;
else
    z = sqrt((dss + dsr + e)^2 + a^2) - d;
end

lambda = 340 ./ freqHz;
if e == 0
    C3 = ones(size(lambda));
else
    C3 = (1 + (5*lambda./e).^2) ./ (1/3 + (5*lambda./e).^2);
end

zmin = -2*lambda ./ (C2*C3);

Dz = zeros(size(lambda));
above = z > zmin;
if any(above(:))
    dMax = max(dss, dsr);
    dMin = min(dss, dsr);
    Kmet = exp(-(1/2000) * sqrt((dMax + e) .* dMin .* d ./ (2*(z - zmin(above)))));
    Dz(above) = 10*log10(1 + (2 + C2./lambda(above)) .* C3(above) .* z .* Kmet);
end

if Agr > 0
    Abar = max(Dz - Agr, 0);
else
    Abar = max(Dz, 0);
end
end
