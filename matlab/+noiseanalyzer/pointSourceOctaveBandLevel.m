function Lp = pointSourceOctaveBandLevel(Lw, Dc, Adiv, Aatm, Agr, Abar, Amisc)
%POINTSOURCEOCTAVEBANDLEVEL Equivalent continuous downwind octave-band SPL at the receiver due
%   to one point source, ISO 9613-2:1996 eqs.(3)-(4): Lp = Lw + Dc - A,
%   A = Adiv + Aatm + Agr + Abar + Amisc.
arguments
    Lw double     % octave-band sound power level, dB re 1 pW
    Dc double = 0 % directivity correction, dB
    Adiv double = 0
    Aatm double = 0
    Agr double = 0
    Abar double = 0
    Amisc double = 0
end
A = Adiv + Aatm + Agr + Abar + Amisc;
Lp = Lw + Dc - A;
end
