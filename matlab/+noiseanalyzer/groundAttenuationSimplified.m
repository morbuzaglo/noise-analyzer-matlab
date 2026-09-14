function Agr = groundAttenuationSimplified(hm, d)
%GROUNDATTENUATIONSIMPLIFIED Alternative A-weighted-only ground attenuation, ISO 9613-2:1996
%   eq.(10): Agr = max(0, 4.8 - (2*hm/d)*(17 + 300/d)) dB. Valid only when: only the A-weighted
%   level matters, propagation is over porous or mostly-porous ground, the source is not a pure
%   tone, and for ground surfaces of any shape.
arguments
    hm double  % mean propagation-path height above ground, m (Fig. 3: hm = F/d)
    d double   % source-to-receiver distance, m
end
Agr = max(0, 4.8 - (2*hm./d).*(17 + 300./d));
end
