function [flow, fhigh] = octaveBandEdges(fm, fraction)
%OCTAVEBANDEDGES Lower/upper band-edge frequencies for band-center frequency(ies) fm,
%   IEC 61260-1:2014 eq 4-5.
arguments
    fm double
    fraction (1,1) double = 1
end
G = 10^(3/10);
flow = fm .* G.^(-1/(2*fraction));
fhigh = fm .* G.^(+1/(2*fraction));
end
