function Lband = octaveBandSpectrumFFT(p, fs, bands, referencePressure)
%OCTAVEBANDSPECTRUMFFT Approximate octave-band equivalent levels via FFT energy summation.
%   NOT a substitute for true IEC 61260-1 band-pass filtering (that filterbank is not yet built
%   in this package — see README roadmap). This sums FFT bin power within each nominal octave's
%   exact band edges (IEC 61260-1 eq.4-5) as a quick spectral estimate for plotting; label it as
%   an estimate in any report, not a certified band measurement.
%
%   Scaling: bin power is normalized so that summing it over ALL bins (DC to fs) exactly
%   reproduces mean(p.^2) (Parseval's theorem), then folded to one-sided (0 to Nyquist) by
%   doubling non-DC/non-Nyquist bins -- so summing Lband's underlying linear powers over bands
%   spanning the full spectrum reproduces the overall (unweighted) Leq.
arguments
    p (:,1) double
    fs (1,1) double
    bands (1,:) double = noiseanalyzer.iso9613OctaveBands()
    referencePressure (1,1) double = noiseanalyzer.referencePressure()
end
n = numel(p);
P = fft(p);
binPower = (abs(P).^2) / n^2; % linear power per bin; sum over all n bins = mean(p.^2)

halfN = floor(n/2) + 1;
onesidedPower = binPower(1:halfN);
if mod(n, 2) == 0
    onesidedPower(2:end-1) = onesidedPower(2:end-1) * 2; % fold mirrors, exclude DC & Nyquist
else
    onesidedPower(2:end) = onesidedPower(2:end) * 2; % odd n: no exact Nyquist bin
end
freqs = (0:halfN-1)' * (fs/n);

Lband = nan(1, numel(bands));
for k = 1:numel(bands)
    [flo, fhi] = noiseanalyzer.octaveBandEdges(bands(k), 1);
    inBand = freqs >= flo & freqs < fhi;
    bandPower = sum(onesidedPower(inBand));
    if bandPower <= 0
        Lband(k) = -Inf;
    else
        Lband(k) = 10*log10(bandPower / referencePressure^2);
    end
end
end
