function v = percentileLevel(x, pct)
%PERCENTILELEVEL Percentile of a level trace via linear interpolation on the sorted data —
%   a minimal implementation so the package has no Statistics and Machine Learning Toolbox
%   dependency (matches the no-toolbox-assumed design in bilinearTransform.m).
arguments
    x double
    pct (1,1) double
end
x = sort(x(:));
n = numel(x);
if n == 1
    v = x;
    return
end
r = (pct/100)*(n-1) + 1;
lo = floor(r);
hi = ceil(r);
frac = r - lo;
v = x(lo) + frac*(x(hi) - x(lo));
end
