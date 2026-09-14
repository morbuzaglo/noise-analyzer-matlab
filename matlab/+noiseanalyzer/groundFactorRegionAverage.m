function G = groundFactorRegionAverage(Gn, dn)
%GROUNDFACTORREGIONAVERAGE Length-weighted ground factor for a region built from multiple
%   sections with different ground factors, ISO 9613-2:2024 eq.(10): G = sum(Gn.*dn)/sum(dn).
%   New in the 2024 edition (1996 assumed one uniform G per region). Feed the result as
%   Gs/Gr/Gm into groundAttenuation when a region isn't acoustically uniform.
arguments
    Gn (1,:) double
    dn (1,:) double
end
G = sum(Gn .* dn) / sum(dn);
end
