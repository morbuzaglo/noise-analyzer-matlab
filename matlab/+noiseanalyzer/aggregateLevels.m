function agg = aggregateLevels(levels, method)
%AGGREGATELEVELS Combine a vector of dB level values into a single aggregate value.
%   method "mean" (default) computes the energetic (power) mean:
%   10*log10(mean(10.^(levels/10))) -- the physically correct way to average sound *levels*,
%   not a simple arithmetic mean of the dB values themselves.
%   method "max" returns max(levels).
%   NaN entries are ignored; returns NaN if levels is empty or all-NaN.
arguments
    levels double
    method (1,1) string {mustBeMember(method, ["mean", "max"])} = "mean"
end
levels = levels(:);
levels = levels(~isnan(levels));
if isempty(levels)
    agg = NaN;
    return
end
if method == "mean"
    agg = 10*log10(mean(10.^(levels/10)));
else
    agg = max(levels);
end
end
