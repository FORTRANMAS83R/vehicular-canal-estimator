function [r, a] = simulate_rician_rx(s, Att_dB, fd, theta, K, los_index, tau, fs)
% SIMULATE_RICIAN_RX
% Simule un canal Rician multipath avec délais et retourne le signal reçu
%
% Entrées :
%   s          : signal transmis [Nx1]
%   Att_dB     : atténuations en dB [1xP]
%   fd         : Doppler shifts par chemin [1xP]
%   theta      : phases initiales [1xP]
%   K          : facteur de Rician global
%   los_index  : index du chemin LOS
%   tau        : délais en secondes [1xP]
%   fs         : fréquence d'échantillonnage [Hz]
%
% Sorties :
%   r          : signal reçu [Nx1]
%   a          : coefficients de canal [NxP]
s = s / sqrt(mean(abs(s).^2));  % normalise à 1 watt

N = length(s);
NbPaths = length(Att_dB);
t = (0:N-1)' / fs;

% === Étape 1 : puissances et amplitudes
Omega = 10.^(Att_dB / 10);
alpha = sqrt(Omega);

% === Étape 2 : génération des coefficients de canal a_k(t)
a = zeros(N, NbPaths);

for k = 1:NbPaths
    z_k = (randn(N,1) + 1j*randn(N,1)) / sqrt(2);
    if k == los_index
        a(:,k) = alpha(k) * ( ...
            sqrt(K/(K+1)) * exp(1j*(2*pi*fd(k)*t + theta(k))) + ...
            sqrt(1/(K+1)) * z_k );
    else
        a(:,k) = alpha(k) * z_k;
    end
end

% === Étape 3 : application des délais (en échantillons)
delays_samples = round(tau * fs);
r = zeros(N,1);

for k = 1:NbPaths
    d = delays_samples(k);
    if d < N
        r((d+1):end) = r((d+1):end) + a(1:(end-d),k) .* s(1:(end-d));
    end
end
end
