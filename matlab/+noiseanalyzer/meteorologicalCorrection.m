function Cmet = meteorologicalCorrection(hs, hr, dp, C0)
%METEOROLOGICALCORRECTION Long-term meteorological correction, ISO 9613-2:1996 eqs.(21)-(22),
%   for a point source with effectively time-constant output. C0 depends on local meteorological
%   statistics (wind speed/direction, temperature gradients); practical range is 0-5 dB, with
%   values above 2 dB exceptional (standard's Note 22). Default C0=0 reproduces eq.(21) alone.
arguments
    hs (1,1) double
    hr (1,1) double
    dp (1,1) double
    C0 (1,1) double = 0
end
threshold = 10*(hs + hr);
if dp <= threshold
    Cmet = 0;
else
    Cmet = C0 * (1 - threshold/dp);
end
end
