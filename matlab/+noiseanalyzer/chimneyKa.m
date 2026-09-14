function ka = chimneyKa(a, freqHz, temperatureCelsius)
%CHIMNEYKA Dimensionless wavenumber-times-opening-radius parameter ka for the chimney-stack
%   directivity correction, ISO 9613-2:2024 Annex B.1 eq.(B.3):
%   ka = 2*pi*a*f / [331.4*sqrt(1 + T/273)], T in degrees Celsius.
%   a = chimney-opening radius (m); freqHz = octave-band nominal frequency (may be a vector);
%   temperatureCelsius = temperature at the chimney mouth.
arguments
    a (1,1) double
    freqHz double
    temperatureCelsius (1,1) double
end
ka = 2*pi*a*freqHz ./ (331.4*sqrt(1 + temperatureCelsius/273));
end
