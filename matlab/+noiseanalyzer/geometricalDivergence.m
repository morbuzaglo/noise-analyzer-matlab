function Adiv = geometricalDivergence(d, d0)
%GEOMETRICALDIVERGENCE Attenuation due to spherical spreading from a point source,
%   ISO 9613-2:1996 eq.(7): Adiv = 20*lg(d/d0) + 11 dB.
arguments
    d double            % source-to-receiver distance, m
    d0 (1,1) double = 1 % reference distance, m
end
Adiv = 20*log10(d./d0) + 11;
end
