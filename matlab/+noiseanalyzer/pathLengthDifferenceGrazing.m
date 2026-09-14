function z = pathLengthDifferenceGrazing(zn)
%PATHLENGTHDIFFERENCEGRAZING Controlling path-length difference when the direct line of sight is
%   NOT blocked but grazes past one or more edges, ISO 9613-2:2024 eq.(23): z = max(zn), where
%   each zn is computed via pathLengthDifferenceOverTop (eq.22) with e=0 for that edge alone (zn
%   is negative for an unblocked path per eq.22's sign convention).
arguments
    zn (1,:) double
end
z = max(zn);
end
