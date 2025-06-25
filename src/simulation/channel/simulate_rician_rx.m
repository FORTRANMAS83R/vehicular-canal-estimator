%
% simulate_rician_rx - Simulates a multipath Rician fading channel with delays.
%
% Syntax:
%   [r, a] = simulate_rician_rx(s, Att_dB, fd, theta, K, los_index, tau, fs)
%
% Description:
%   This function simulates the effect of a multipath Rician fading channel with delays
%   on a transmitted signal. It generates the channel coefficients for each path, applies
%   the appropriate Doppler shift, phase, and delay, and returns the received signal as well
%   as the channel coefficients for each path.
%
% Inputs:
%   s         : [N x 1] Transmitted signal vector
%   Att_dB    : [1 x P] Path attenuations in dB
%   fd        : [1 x P] Doppler shifts for each path (Hz)
%   theta     : [1 x P] Initial phases for each path (radians)
%   K         : Scalar, global Rician K-factor (linear)
%   los_index : Index of the Line-Of-Sight (LOS) path (integer)
%   tau       : [1 x P] Path delays (seconds)
%   fs        : Sampling frequency (Hz)
%
% Outputs:
%   r         : [N x 1] Received signal vector
%   a         : [N x P] Channel coefficients for each path
% Notes:
%   - The input signal is normalized to unit average power.
%   - The LOS path is modeled with the Rician K-factor, while other paths are Rayleigh.
%   - Delays are applied in integer samples (rounded).
%   - The output 'a' contains the time-varying channel coefficients for each path.
%
% Author: Mikael Franco
%

function [r, a] = simulate_rician_rx(s, Att_dB, fd, theta, K, los_index, tau, fs)
% Normalize input signal to unit average power
s = s / sqrt(mean(abs(s).^2));

N = length(s);
NbPaths = length(Att_dB);
t = (0:N-1)' / fs;

%% Compute path powers and amplitudes
Omega = 10.^(Att_dB / 10);
alpha = sqrt(Omega);

%% Generate channel coefficients a_k(t) for each path
a = zeros(N, NbPaths);

for k = 1:NbPaths
    z_k = (randn(N,1) + 1j*randn(N,1)) / sqrt(2); % Complex Gaussian noise
    if k == los_index
        % LOS path: Rician fading
        a(:,k) = alpha(k) * ( ...
            sqrt(K/(K+1)) * exp(1j*(2*pi*fd(k)*t + theta(k))) + ...
            sqrt(1/(K+1)) * z_k );
    else
        % NLOS path: Rayleigh fading
        a(:,k) = alpha(k) * z_k;
    end
end

%% Apply delays (in samples) and sum contributions
delays_samples = round(tau * fs);
r = zeros(N,1);

for k = 1:NbPaths
    d = delays_samples(k);
    if d < N
        r((d+1):end) = r((d+1):end) + a(1:(end-d),k) .* s(1:(end-d));
    end
end
end
