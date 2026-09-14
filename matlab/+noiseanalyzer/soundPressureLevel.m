function Lp = soundPressureLevel(p, p0)
%SOUNDPRESSURELEVEL Sound pressure level Lp = 20*log10(|p|/p0), ISO/TR 25417:2007 sec 2.2.
arguments
    p double
    p0 (1,1) double = noiseanalyzer.referencePressure()
end
Lp = 20*log10(abs(p) ./ p0);
end
