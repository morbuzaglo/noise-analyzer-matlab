function Leq = equivalentLevel(p, p0)
%EQUIVALENTLEVEL Equivalent-continuous sound pressure level Leq (linear time-average of p^2),
%   ISO/TR 25417:2007 sec 2.2 / IEC 61672-1:2013.
arguments
    p (:,1) double
    p0 (1,1) double = noiseanalyzer.referencePressure()
end
Leq = 10*log10(mean(p.^2) ./ p0^2);
end
