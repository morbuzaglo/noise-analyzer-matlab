function A = groundAttenuationSourceOrReceiverTerm(freqHz, G, h, dp)
%GROUNDATTENUATIONSOURCEORRECEIVERTERM As or Ar contribution to ground attenuation for one
%   octave band, ISO 9613-2:2024 Table 3 (byte-for-byte identical to ISO 9613-2:1996 Table 3 --
%   only how As/Ar/Am combine into Agr changed in 2024, see groundAttenuation). Call with
%   (freq,Gs,hs,dp) for As, (freq,Gr,hr,dp) for Ar. G: hard ground = 0, porous = 1, mixed =
%   fraction porous.
arguments
    freqHz (1,1) double
    G (1,1) double
    h (1,1) double
    dp (1,1) double
end
switch freqHz
    case 63
        A = -1.5;
    case 125
        A = -1.5 + G*aPrime(h, dp);
    case 250
        A = -1.5 + G*bPrime(h, dp);
    case 500
        A = -1.5 + G*cPrime(h, dp);
    case 1000
        A = -1.5 + G*dPrime(h, dp);
    case {2000, 4000, 8000}
        A = -1.5*(1 - G);
    otherwise
        error('noiseanalyzer:groundAttenuationSourceOrReceiverTerm:badFrequency', ...
            'freqHz must be one of the ISO 9613-2 nominal octave bands (63-8000 Hz).');
end
end

function v = aPrime(h, dp)
v = 1.5 + 3.0*exp(-0.12*(h-5)^2)*(1-exp(-dp/50)) + 5.7*exp(-0.09*h^2)*(1-exp(-2.8e-6*dp^2));
end

function v = bPrime(h, dp)
v = 1.5 + 8.6*exp(-0.09*h^2)*(1-exp(-dp/50));
end

function v = cPrime(h, dp)
v = 1.5 + 14.0*exp(-0.46*h^2)*(1-exp(-dp/50));
end

function v = dPrime(h, dp)
v = 1.5 + 5.0*exp(-0.9*h^2)*(1-exp(-dp/50));
end
