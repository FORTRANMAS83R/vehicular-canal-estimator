% filepath: c:\code\liu\vehicular-canal-estimator\src\estimator\estimate_K_stat.m
% Estimate K-factor from a raw .h5 file using a statistical estimator, then compute RMSE and R²
% filepath: c:\code\liu\vehicular-canal-estimator\src\estimator\plot_rmse_r2_vs_snr.m
% Boucle sur SNR de 0 à 20, appelle estimate_K_stat, stocke et plot RMSE et R2

rmse_vec = zeros(21,1);
r2_vec = zeros(21,1);

for snr = 0:20
    filename = sprintf('data/samples/multiple_snr/snr_%d_dB.h5', snr);
    if exist(filename, 'file')
        [rmse, R2] = estimate_K_stat(filename);
        rmse_vec(snr+1) = rmse;
        r2_vec(snr+1) = R2;
    else
        warning('File %s not found.', filename);
        rmse_vec(snr+1) = NaN;
        r2_vec(snr+1) = NaN;
    end
end

figure;
subplot(2,1,1);
plot(0:20, rmse_vec, 'o-');
xlabel('SNR (dB)');
ylabel('RMSE');
title('RMSE vs SNR');
grid on;

subplot(2,1,2);
plot(0:20, r2_vec, 's-');
xlabel('SNR (dB)');
ylabel('R^2');
title('R^2 vs SNR');
grid on;
function [rmse, R2] = estimate_K_stat(h5file)
disp(h5file)
% Lecture des signaux
info = h5info(h5file);
datasets = {info.Datasets.Name};
real_idx = find(contains(datasets, '_real'));
N = numel(real_idx);

K_true = zeros(N,1);
K_est  = zeros(N,1);

for i = 1:N
    real_part = h5read(h5file, sprintf('/sample_%d_real', i));
    imag_part = h5read(h5file, sprintf('/sample_%d_imag', i));
    x = real_part + 1i*imag_part;
    K_true(i) = h5read(h5file, sprintf('/sample_%d_K', i));
        h_hat = mean(x) / mean(abs(x));
    % if abs(h_hat) > 0
    %     x = x / h_hat;
    % else
    %     x = x;
    % end
    % Estimation statistique du K-factor (méthode de moments)
    mu = mean(abs(x));
    sigma2 = var(abs(x));

    %K_est(i) = max(0, mu^2 / sigma2 - 1); % K-factor estimation
    if sigma2 > 0
        K_est(i) = (mu^2 - sigma2) / (2*sigma2);
    else
        K_est(i) = 0;
    end

end

% Affichage des valeurs estimées et vraies


% Calcul RMSE et R²
rmse = sqrt(mean((K_est - K_true).^2));
R2 = 1 - sum((K_est - K_true).^2) / sum((K_true - mean(K_true)).^2);


%fprintf('Statistical K-factor estimation: RMSE = %.4f, R2 = %.4f\n', rmse, R2);


end