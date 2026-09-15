function [uniqueDistances, aggregatedLevels, groupIndex] = groupLevelsByDistance(distances, levels, aggregationMethod, tolerance)
%GROUPLEVELSBYDISTANCE Group measured levels by microphone distance (several microphones at the
%   same, or nearly the same, radius from the source are combined into one aggregate level per
%   distance), then aggregate each group energetically via aggregateLevels.
%
%   Distances within `tolerance` metres of each other are treated as the same group (clustered by
%   sorting and thresholding consecutive gaps, so results don't depend on input order). Each
%   group's reported distance is the mean of the distances assigned to it.
%
%   uniqueDistances  - sorted, one row per distance group, m
%   aggregatedLevels - aggregateLevels(...) of the levels in each group, dB
%   groupIndex       - group number (1..numel(uniqueDistances)) for each input entry, same order
%                       as distances/levels
arguments
    distances (:,1) double
    levels (:,1) double
    aggregationMethod (1,1) string {mustBeMember(aggregationMethod, ["mean", "max"])} = "mean"
    tolerance (1,1) double = 0.5
end
if numel(distances) ~= numel(levels)
    error('noiseanalyzer:groupLevelsByDistance:SizeMismatch', ...
        'distances and levels must have the same number of elements.');
end

n = numel(distances);
groupIndex = zeros(n, 1);
[sortedDistances, sortOrder] = sort(distances);

currentGroup = 0;
groupStartValue = -inf;
sortedGroupIndex = zeros(n, 1);
for i = 1:n
    if i == 1 || (sortedDistances(i) - groupStartValue) > tolerance
        currentGroup = currentGroup + 1;
        groupStartValue = sortedDistances(i);
    end
    sortedGroupIndex(i) = currentGroup;
end
groupIndex(sortOrder) = sortedGroupIndex;

nGroups = currentGroup;
uniqueDistances = zeros(nGroups, 1);
aggregatedLevels = zeros(nGroups, 1);
for g = 1:nGroups
    inGroup = groupIndex == g;
    uniqueDistances(g) = mean(distances(inGroup));
    aggregatedLevels(g) = noiseanalyzer.aggregateLevels(levels(inGroup), aggregationMethod);
end

[uniqueDistances, order] = sort(uniqueDistances);
aggregatedLevels = aggregatedLevels(order);
remap = zeros(nGroups, 1);
remap(order) = 1:nGroups;
groupIndex = remap(groupIndex);
end
