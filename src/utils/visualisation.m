% % filepath: c:\code\liu\vehicular-canal-estimator\src\estimator\estimate_K_stat.m
% % Estimate K-factor from a raw .h5 file using a statistical estimator, then compute RMSE and R²
% % filepath: c:\code\liu\vehicular-canal-estimator\src\estimator\plot_rmse_r2_vs_snr.m
% % Boucle sur SNR de 0 à 20, appelle estimate_K_stat, stocke et plot RMSE et R2

% rmse_vec = zeros(21,1);
% r2_vec = zeros(21,1);

% for snr = 0:20
%     filename = sprintf('data/samples/multiple_snr/snr_%d_dB.h5', snr);
%     if exist(filename, 'file')
%         [rmse, R2] = estimate_K_stat(filename);
%         rmse_vec(snr+1) = rmse;
%         r2_vec(snr+1) = R2;
%     else
%         warning('File %s not found.', filename);
%         rmse_vec(snr+1) = NaN;
%         r2_vec(snr+1) = NaN;
%     end
% end

% figure;
% subplot(2,1,1);
% plot(0:20, rmse_vec, 'o-');
% xlabel('SNR (dB)');
% ylabel('RMSE');
% title('RMSE vs SNR');
% grid on;

% subplot(2,1,2);
% plot(0:20, r2_vec, 's-');
% xlabel('SNR (dB)');
% ylabel('R^2');
% title('R^2 vs SNR');
% grid on;
% function [rmse, R2] = estimate_K_stat(h5file)
% disp(h5file)
% % Lecture des signaux
% info = h5info(h5file);
% datasets = {info.Datasets.Name};
% real_idx = find(contains(datasets, '_real'));
% N = numel(real_idx);

% K_true = zeros(N,1);
% K_est  = zeros(N,1);

% for i = 1:N
%     real_part = h5read(h5file, sprintf('/sample_%d_real', i));
%     imag_part = h5read(h5file, sprintf('/sample_%d_imag', i));
%     x = real_part + 1i*imag_part;
%     K_true(i) = h5read(h5file, sprintf('/sample_%d_K', i));
%         h_hat = mean(x) / mean(abs(x));
%     % if abs(h_hat) > 0
%     %     x = x / h_hat;
%     % else
%     %     x = x;
%     % end
%     % Estimation statistique du K-factor (méthode de moments)
%     mu = mean(abs(x));
%     sigma2 = var(abs(x));

%     %K_est(i) = max(0, mu^2 / sigma2 - 1); % K-factor estimation
%     if sigma2 > 0
%         K_est(i) = (mu^2 - sigma2) / (2*sigma2);
%     else
%         K_est(i) = 0;
%     end

% end

% % Affichage des valeurs estimées et vraies


% % Calcul RMSE et R²
% rmse = sqrt(mean((K_est - K_true).^2));
% R2 = 1 - sum((K_est - K_true).^2) / sum((K_true - mean(K_true)).^2);


% %fprintf('Statistical K-factor estimation: RMSE = %.4f, R2 = %.4f\n', rmse, R2);


% end

function plot_CDF()
    % Paramètres du canal Rician
h5file = 'data/samples/multiple_snr/snr_0_dB.h5'; % À adapter

% Lecture du premier sample (1000 échantillons)
real_part = h5read(h5file, '/sample_200_real');
imag_part = h5read(h5file, '/sample_200_imag');
K1 = h5read(h5file, '/sample_200_K');
K = K1; % Facteur K en linéaire

s = sqrt(K / (K + 1));         % Amplitude LOS
sigma = sqrt(1 / (2 * (K + 1))); % Écart-type bruit (par composante I ou Q)
disp([K, s, sigma])

% Module du signal réel (normalisé)
r = sqrt(real_part.^2 + imag_part.^2);
r = r / mean(r);

% CDF empirique
[emp_cdf, emp_r] = ecdf(r);

% CDF théorique
r_th = linspace(0, max([max(r), 5*sigma]), 1000);
b = s / sigma;  % paramètre de forme
cdf_th = 1 - marcumq(b, r_th / sigma);  % Fonction CDF de Rice avec marcumq
cdf_th_interp = interp1(r_th, cdf_th, emp_r, 'linear', 'extrap');

disp('disp([min(r_th/sigma), max(r_th/sigma)]);')
disp([min(r_th/sigma), max(r_th/sigma)]);
disp('disp([min(cdf_th), max(cdf_th)]);')
disp([min(cdf_th), max(cdf_th)]);
disp(['Empirical mean: ', num2str(mean(r)), ', sigma: ', num2str(std(r))]);
disp(['Theoretical s: ', num2str(s), ', sigma: ', num2str(sigma)]);

ks_dist = max(abs(emp_cdf - cdf_th_interp));
fprintf('Distance de Kolmogorov-Smirnov : %.4f\n', ks_dist);

% Calcul du MSE
rmse = mean((emp_cdf - cdf_th_interp).^2);
fprintf('MSE entre CDF empirique et théorique : %.4e\n', rmse);

% Tracé
figure;
plot(emp_r, emp_cdf, 'b', 'LineWidth', 1.5); hold on;
plot(r_th, cdf_th, 'r--', 'LineWidth', 1.5);
legend('CDF empirique', 'CDF théorique (Rice)');
xlabel('Amplitude');
ylabel('CDF');
title(['CDFs comparaison (K = ' num2str(K) ' )']);
txt = sprintf('RMSE = %.4f\nKS = %.4f', rmse, ks_dist);
xpos = 0.05 * max(emp_r);
ypos = 0.2;
text(xpos, ypos, txt, 'FontSize', 12, 'BackgroundColor', 'w', 'EdgeColor', 'k');
grid on;

% filepath: c:\code\liu\vehicular-canal-estimator\src\utils\plot_all_cdfs_from_h5.m
% Trace les CDFs empiriques de tous les samples d'un fichier .h5 sur la même figure

h5file = 'data/samples/multiple_snr/snr_10_dB.h5'; % À adapter
num_samples = 500; % À adapter selon ton fichier

figure; hold on;
for i = 1:num_samples
    real_part = h5read(h5file, sprintf('/sample_%d_real', i));
    imag_part = h5read(h5file, sprintf('/sample_%d_imag', i));
    r = sqrt(real_part.^2 + imag_part.^2);
    r = r / mean(r); % Normalisation (optionnelle)
    [emp_cdf, emp_r] = ecdf(r);
    plot(emp_r, emp_cdf, 'Color', [0 0.447 0.741 0.08]); % Couleur bleue, opacité réduite (alpha=0.08)
end
xlabel('Amplitude');
ylabel('CDF');
title('CDFs empiriques superposées pour tous les samples');
grid on;
hold off;

% filepath: c:\code\liu\vehicular-canal-estimator\src\utils\plot_all_cdfs_from_h5.m
% Trace les CDFs empiriques de tous les samples + le CDF théorique moyen

h5file = 'data/samples/multiple_snr/snr_10_dB.h5'; % À adapter
num_samples = 500; % À adapter selon ton fichier

all_K = zeros(num_samples,1);

figure; hold on;
for i = 1:num_samples
    real_part = h5read(h5file, sprintf('/sample_%d_real', i));
    imag_part = h5read(h5file, sprintf('/sample_%d_imag', i));
    r = sqrt(real_part.^2 + imag_part.^2);
    r = r / mean(r); % Normalisation (optionnelle)
    [emp_cdf, emp_r] = ecdf(r);
    plot(emp_r, emp_cdf, 'Color', [0 0.447 0.741 0.08]); % CDF empirique, opacité faible
    all_K(i) = h5read(h5file, sprintf('/sample_%d_K', i));
end

% Calcul du CDF théorique moyen (avec K moyen)
K_mean = mean(all_K);
s = sqrt(K_mean / (K_mean + 1));
sigma = sqrt(1 / (2 * (K_mean + 1)));
r_th = linspace(0, 3, 1000); % Plage d'amplitude normalisée
b = s / sigma;
cdf_th = 1 - marcumq(b, r_th / sigma);

plot(r_th, cdf_th, 'r-', 'LineWidth', 2, 'DisplayName', 'CDF théorique (K moyen)');

xlabel('Amplitude');
ylabel('CDF');
title('empirical CDFs and theoretical CDF ');
legend('show');
grid on;
hold off;

% filepath: c:\code\liu\vehicular-canal-estimator\src\utils\plot_all_cdfs_from_h5.m
% Trace les CDFs empiriques de tous les samples + CDF théorique moyen
% Calcule le RMSE et le KS pour chaque sample et affiche les moyennes

h5file = 'data/samples/multiple_snr/snr_10_dB.h5'; % À adapter
num_samples = 500; % À adapter selon ton fichier

all_K = zeros(num_samples,1);
all_KS = zeros(num_samples,1);
all_RMSE = zeros(num_samples,1);

figure; hold on;
h_emp = []; % Pour garder un handle sur une courbe empirique
for i = 1:num_samples
    real_part = h5read(h5file, sprintf('/sample_%d_real', i));
    imag_part = h5read(h5file, sprintf('/sample_%d_imag', i));
    r = sqrt(real_part.^2 + imag_part.^2);
    r = r / mean(r); % Normalisation (optionnelle)
    [emp_cdf, emp_r] = ecdf(r);
    h = plot(emp_r, emp_cdf, 'Color', [0 0.447 0.741 0.08]); % CDF empirique, opacité faible
    if i == 1
        h_emp = h; % On garde le handle de la première courbe empiriques
    end
    all_K(i) = h5read(h5file, sprintf('/sample_%d_K', i));

    % CDF théorique pour ce sample
    K = all_K(i);
    s = sqrt(K / (K + 1));
    sigma = sqrt(1 / (2 * (K + 1)));
    r_th = linspace(0, max([max(r), 3]), 1000);
    b = s / sigma;
    cdf_th = 1 - marcumq(b, r_th / sigma);
    cdf_th_interp = interp1(r_th, cdf_th, emp_r, 'linear', 'extrap');

    % Calcul des métriques
    all_KS(i) = max(abs(emp_cdf - cdf_th_interp));
    all_RMSE(i) = sqrt(mean((emp_cdf - cdf_th_interp).^2));
end

% CDF théorique moyen (avec K moyen)
K_mean = mean(all_K);
s = sqrt(K_mean / (K_mean + 1));
sigma = sqrt(1 / (2 * (K_mean + 1)));
r_th = linspace(0, 3, 1000);
b = s / sigma;
cdf_th = 1 - marcumq(b, r_th / sigma);
h_th = plot(r_th, cdf_th, 'r-', 'LineWidth', 2);

% Moyennes des métriques
mean_KS = mean(all_KS);
mean_RMSE = mean(all_RMSE);

% Affichage sur la figure
txt = sprintf('KS moyen = %.4f\nRMSE moyen = %.4f', mean_KS, mean_RMSE);
xpos = 0.05 * max(r_th);
ypos = 0.2;
text(xpos, ypos, txt, 'FontSize', 12, 'BackgroundColor', 'w', 'EdgeColor', 'k');

xlabel('Amplitude');
ylabel('CDF');
title('Theoretical and empirical CDFs ');
legend([h_emp h_th], {'empirical CDF', 'theorical CDF'}, 'Location', 'best');
grid on;
hold off;
end 


function plot_estimation_perf()
    % filepath: c:\code\liu\vehicular-canal-estimator\src\estimator\neural_networks\plot_train_K_estimator_results.m
% Parse train_K_estimator_results.txt and plot the results

filename = 'data/train_K_estimator_results.txt';
results = dlmread(filename);

figure;

subplot(2,1,1);
plot(results(:,1), 'o-');
xlabel('File #');
ylabel('RMSE');
title('RMSE per file');
grid on;

subplot(2,1,2);
plot(results(:,2), 'o-', 'DisplayName', 'R^2');
hold on;
plot(results(:,3), 's-', 'DisplayName', 'R^2 lin');
xlabel('File #');
ylabel('R^2');
title('R^2 and R^2 lin per file');
legend;
grid on;
end 

plot_feature_correlation('data/features/dataset_1/snr_0_dB_features.mat');
% filepath: src/utils/plot_feature_correlation.m
function plot_feature_correlation(mat_filename)
% plot_feature_correlation - Trace la matrice de corrélation des features avec noms
%
% Le fichier .mat doit contenir une variable 'all_features' (N x 29)

data = load(mat_filename, 'all_features');
features = data.all_features;

corr_matrix = corrcoef(features);

% Noms des 29 features
feature_names = { ...
    'Energy', ...
    'AvgPower', ...
    'Variance', ...
    'Skewness', ...
    'Kurtosis', ...
    'MaxAmp', ...
    'MedianAmp', ...
    'Q25', ...
    'Q75' ...
};
for k = 1:20
    feature_names{end+1} = sprintf('mag_%d', k);
end

figure;
imagesc(corr_matrix);
colorbar;
title('Correlation matrice of features');
xlabel('Feature');
ylabel('Feature');
axis square;
set(gca, 'XTick', 1:29, 'XTickLabel', feature_names, ...
         'YTick', 1:29, 'YTickLabel', feature_names, ...
         'XTickLabelRotation', 90, 'FontSize',8); 
set(gca, 'TickLength', [0, 0])
end 

ks_test_rice('data/samples/multiple_snr/snr_0_dB.h5')
function ks_test_rice(h5_filename)
% ks_test_rice - Teste si le premier sample d'un fichier .h5 suit une loi de Rice
%
% Utilisation :
%   ks_test_rice('data/mon_fichier.h5')

% Lecture du premier sample (parties réelle et imaginaire)
real_part = h5read(h5_filename, '/sample_1_real');
imag_part = h5read(h5_filename, '/sample_1_imag');
x = real_part + 1i * imag_part;
r = abs(x);

% Estimation des paramètres de la loi de Rice (méthode des moments)
mu = sqrt(mean(r)^2 - var(r));
sigma = sqrt(0.5 * (var(r)));

% Génération d'une distribution de Rice simulée avec ces paramètres
rice_dist = makedist('Rician', 's', mu, 'sigma', sigma);

% Test de Kolmogorov-Smirnov
[h, p] = kstest(r, 'CDF', rice_dist);

% Préparation du titre selon le résultat du test
if h == 0
    test_str = sprintf('Test KS validé (p = %.3g)', p);
else
    test_str = sprintf('rejected (p = %.3g)', p);
end

% Affichage des distributions
figure;
histogram(r, 'Normalization', 'pdf');
hold on;
xvals = linspace(min(r), max(r), 100);
plot(xvals, pdf(rice_dist, xvals), 'r', 'LineWidth', 2);
legend('Data', 'Rician');
title(['Test KS  - ' test_str]);
xlabel('|x|');
ylabel('Density of probability');
hold off;
end