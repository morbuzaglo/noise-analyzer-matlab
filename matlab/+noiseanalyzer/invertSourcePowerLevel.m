function Lw = invertSourcePowerLevel(Lp, Dc, Adiv, Aatm, Agr, Abar, Amisc)
%INVERTSOURCEPOWERLEVEL Octave-band sound power level Lw implied by a measured receiver SPL Lp,
%   the algebraic inverse of pointSourceOctaveBandLevel (ISO 9613-2:1996 eqs.(3)-(4)):
%   Lp = Lw + Dc - A, A = Adiv + Aatm + Agr + Abar + Amisc, so Lw = Lp - Dc + A.
%   Exact given the propagation terms (Adiv/Aatm/Agr/Abar/Amisc) are known/assumed -- this is
%   plain algebra, not an estimate or a fit.
arguments
    Lp double     % measured (or target) octave-band SPL at the receiver, dB
    Dc double = 0 % directivity correction, dB
    Adiv double = 0
    Aatm double = 0
    Agr double = 0
    Abar double = 0
    Amisc double = 0
end
A = Adiv + Aatm + Agr + Abar + Amisc;
Lw = Lp - Dc + A;
end
