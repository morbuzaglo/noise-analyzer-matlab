function tc = timeWeightingConstants(name)
%TIMEWEIGHTINGCONSTANTS FAST/SLOW exponential time-weighting constants (seconds),
%   IEC 61672-1:2013.
arguments
    name (1,1) string {mustBeMember(name, ["FAST","SLOW"])} = "FAST"
end
switch name
    case "FAST"
        tc = 0.125;
    case "SLOW"
        tc = 1.000;
end
end
