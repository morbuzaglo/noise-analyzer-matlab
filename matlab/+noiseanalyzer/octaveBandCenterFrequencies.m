function fm = octaveBandCenterFrequencies(x, fraction)
%OCTAVEBANDCENTERFREQUENCIES Exact octave/fractional-octave band-center frequencies,
%   IEC 61260-1:2014 eq 2-3 (ref frequency 1000 Hz, octave ratio G = 10^(3/10)).
%   Ported from acoustics.standards.iec_61260_1_2014.exact_center_frequency
%   (python-acoustics, BSD-3-Clause).
arguments
    x double              % band index/indices (0 = 1000 Hz)
    fraction (1,1) double = 1  % bandwidth designator b (1 = octave, 3 = third-octave, ...)
end
fr = 1000.0;
G = 10^(3/10);

if mod(fraction, 2) == 1
    fm = fr .* G.^(x ./ fraction);
else
    fm = fr .* G.^((2*x + 1) ./ (2*fraction));
end
end
