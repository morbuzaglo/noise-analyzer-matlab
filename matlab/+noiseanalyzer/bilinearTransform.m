function [b, a] = bilinearTransform(num, den, fs)
%BILINEARTRANSFORM Bilinear (Tustin) transform of an analog transfer function num(s)/den(s)
%   (coefficients in descending powers of s) to a digital transfer function b(z)/a(z), via
%   s -> 2*fs*(z-1)/(z+1) applied on the zero-pole-gain form. Self-contained (uses only roots/
%   poly/conv, all base MATLAB) because Signal Processing Toolbox — which provides BILINEAR —
%   is not installed on this machine.
arguments
    num (1,:) double
    den (1,:) double
    fs (1,1) double
end
za = roots(num);
pa = roots(den);
ka = num(1) / den(1);
c = 2 * fs;

zd = (c + za) ./ (c - za);
pd = (c + pa) ./ (c - pa);

nExtraZeros = numel(pa) - numel(za); % zeros at s=infinity map to z=-1
zd = [zd; -ones(nExtraZeros, 1)];

kd = real(ka * prod(c - za) / prod(c - pa));

b = kd * poly(zd);
a = poly(pd);
end
