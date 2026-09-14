function x = octaveBandIndex(f, fraction)
%OCTAVEBANDINDEX Band index x for a given frequency f. Utility inverse of
%   octaveBandCenterFrequencies; follows from IEC 61260-1:2014 eq 2-3 but the index lookup
%   itself is not part of the standard (same caveat as the python-acoustics reference).
arguments
    f double
    fraction (1,1) double = 1
end
fr = 1000.0;
G = 10^(3/10);
if mod(fraction, 2) == 1
    x = round(fraction .* log(f./fr) ./ log(G));
else
    x = round(2*fraction .* log(f./fr) ./ log(G) - 1) ./ 2;
end
end
