function Lwim = imageSourceLevel(Lw, alpha, Dir)
%IMAGESOURCELEVEL Sound power level of a single-reflection image source, ISO 9613-2:2024 eq.(28):
%   Lw,im = Lw + 10*lg(1-alpha) + Dir dB.
%   alpha = sound absorption coefficient of the reflecting surface (default 0.1 for building
%   facades / industrial-facility surfaces per the standard, if no measured value is available);
%   Dir = directivity index of the source toward the reflector (dB). Supersedes ISO 9613-2:1996
%   eq.(20), which used reflection coefficient rho directly (Lw,im = Lw + 10*lg(rho) + Dir) --
%   physically rho = 1-alpha, so this is the same relationship reparameterized, not a formula
%   change. For the image source's propagation path, compute Adiv/Aatm/Agr/Abar/Amisc (eq.4) and
%   the A-weighting sum (eq.5) using the reflected path's own geometry, same as for a real source.
arguments
    Lw double
    alpha (1,1) double
    Dir double = 0
end
Lwim = Lw + 10*log10(1 - alpha) + Dir;
end
