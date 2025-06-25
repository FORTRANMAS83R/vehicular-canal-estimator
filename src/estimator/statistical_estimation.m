

% filepath: c:\code\liu\vehicular-canal-estimator\src\utils\estimate_K_from_h5.m
% Parse un .h5, estime le facteur K pour chaque sample avec estimate_K_doukas, calcule le MSE
mse = estimate_K_from_h5('data/test_sans_modulation.h5');
function mse = estimate_K_from_h5(h5file)
info = h5info(h5file);
samples = find(contains({info.Datasets.Name}, '_real'));
num_samples = numel(samples);

K_true = zeros(num_samples,1);
K_est = zeros(num_samples,1);

for i = 1:num_samples
    real_part = h5read(h5file, sprintf('/sample_%d_real', i));
    imag_part = h5read(h5file, sprintf('/sample_%d_imag', i));
    r = sqrt(real_part.^2 + imag_part.^2);
    K_true(i) = h5read(h5file, sprintf('/sample_%d_K', i));
    
    % Estimation du facteur K avec la fonction Doukas
    K_est(i) = estimate_K_doukas(abs(r));
end
plot_scatter_K(K_true, K_est);

mse = mean((K_est - K_true).^2);
fprintf('MSE estimation du facteur K (Doukas) : %.4e\n', mse);
end


function K_est = estimate_K_doukas(A)
    % Estimateur du facteur K basé sur Doukas et Kalivas
    % A : vecteur des amplitudes reçues

    % Moments empiriques
    EA = mean(A);
    EA2 = mean(A.^2);
    R = EA / sqrt(EA2);  % Ratio empirique

    % Fonction objectif (erreur entre R et l'expression analytique)
    f = @(K) abs( ...
        R - sqrt(pi / (4 * (K + 1))) * exp(-K / 2) * ...
        ((K + 1) * besseli(0, K / 2) + K * besseli(1, K / 2)) ...
    );

    % Recherche du K qui minimise cette erreur (borne entre 0 et 30 par défaut)
    K_est = fminbnd(f, 0, 30);
end
% filepath: c:\code\liu\vehicular-canal-estimator\src\utils\plot_scatter_K.m
% Trace le scatter plot K réel vs K prédit (échelle log) et affiche le R²

function plot_scatter_K(K_true, K_pred)
    % Filtrage des valeurs positives (log uniquement défini pour >0)
    mask = (K_true > 0) & (K_pred > 0);
    K_true_pos = K_true(mask);
    K_pred_pos = K_pred(mask);

    % Calcul du R²
    R2 = 1 - sum((K_pred_pos - K_true_pos).^2) / sum((K_true_pos - mean(K_true_pos)).^2);

    figure;
    scatter(K_true_pos, K_pred_pos, 40, 'filled');
    hold on;
    mi = min([K_true_pos; K_pred_pos]);
    ma = max([K_true_pos; K_pred_pos]);
    plot([mi, ma], [mi, ma], 'r--', 'LineWidth', 1.5);
    set(gca, 'XScale', 'log', 'YScale', 'log');
    xlabel('K réel');
    ylabel('K prédit');
    title(sprintf('Scatter K réel vs K prédit (log-log)\nR^2 = %.4f', R2));
    grid on;
    hold off;
end