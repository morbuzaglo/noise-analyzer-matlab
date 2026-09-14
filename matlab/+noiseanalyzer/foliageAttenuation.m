function Afol = foliageAttenuation(freqHz, df)
%FOLIAGEATTENUATION Attenuation from propagation through dense foliage, ISO 9613-2:2024 Annex A.2
%   Table A.1 (byte-for-byte identical to ISO 9613-2:1996 Table A.1 -- unchanged). Only counts if
%   the foliage is dense enough to fully block the line of sight; df = total path length through
%   the foliage (m, may be split into a near-source and near-receiver portion per Figure A.1,
%   df = d1+d2). Path lengths under 10 m give no credit (this function returns 0 for df<10, per
%   the standard's table starting at 10 m); over 200 m uses the 200 m value.
arguments
    freqHz double
    df (1,1) double
end
bands = [63, 125, 250, 500, 1000, 2000, 4000, 8000];
flatDb = [0, 0, 1, 1, 1, 1, 2, 3];              % 10 <= df <= 20 m
perMetre = [0.02, 0.03, 0.04, 0.05, 0.06, 0.08, 0.09, 0.12]; % 20 <= df <= 200 m

if df < 10
    Afol = zeros(size(freqHz));
    return
elseif df <= 20
    lookup = flatDb;
else
    dEff = min(df, 200);
    lookup = perMetre * dEff;
end

Afol = arrayfun(@(f) lookup(bands == f), freqHz);
end
