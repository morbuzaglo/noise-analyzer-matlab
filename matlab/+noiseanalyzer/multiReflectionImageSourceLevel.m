function LwimN = multiReflectionImageSourceLevel(Lw, alphaN, Dir)
%MULTIREFLECTIONIMAGESOURCELEVEL Sound power level of an Nth-order multi-reflection image source,
%   ISO 9613-2:2024 eq.(29) -- new in 2024, ISO 9613-2:1996 only covered single reflection:
%   Lw,im,N = Lw + 10*lg[ prod_n(1-alpha_n) ] + Dir dB.
%   alphaN = vector of absorption coefficients at each of the N reflection points along the
%   (bent) path; Dir = directivity index of the source toward the first reflector. Validate the
%   surface-size criterion (reflectionSurfaceSizeCriterion) separately at each reflector, using
%   the possibly-bent total path lengths to/from that reflector.
arguments
    Lw double
    alphaN (1,:) double
    Dir double = 0
end
LwimN = Lw + 10*log10(prod(1 - alphaN)) + Dir;
end
