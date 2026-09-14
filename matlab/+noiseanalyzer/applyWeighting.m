function y = applyWeighting(x, fs, weighting)
%APPLYWEIGHTING Apply A, C, or Z frequency weighting to a signal, IEC 61672-1:2013.
arguments
    x (:,1) double
    fs (1,1) double
    weighting (1,1) string {mustBeMember(weighting, ["A","C","Z"])} = "A"
end
switch weighting
    case "A"
        [b, a] = noiseanalyzer.weightingFilterA(fs);
        y = filter(b, a, x);
    case "C"
        [b, a] = noiseanalyzer.weightingFilterC(fs);
        y = filter(b, a, x);
    case "Z"
        y = x;
end
end
