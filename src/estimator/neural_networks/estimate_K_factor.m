function [rmse, R2, R2_lin] = estimate_K_factor(mat_filename, mode)
warning('off','all');

% Utilise un fichier .mat contenant all_features (N x F) et all_K (N x 1)
% mode = 'train' (défaut) ou 'predict'

if nargin < 2
    mode = "train";
end

%disp("Chargement du fichier .mat...");
data = load(mat_filename, 'all_features', 'all_K');
X_features = data.all_features;
K_true = data.all_K;
N = size(X_features, 1);

%disp("Lecture terminée.");

%% Séparation aléatoire en train/val/test
idx_all = randperm(N);
nTrain = round(0.70 * N);
nVal   = round(0.15 * N);

trainIdx = idx_all(1 : nTrain);
valIdx   = idx_all(nTrain+1 : nTrain+nVal);
testIdx  = idx_all(nTrain+nVal+1 : end);

X_train_feat = X_features(trainIdx, :);
K_train      = K_true(trainIdx);

X_val_feat   = X_features(valIdx, :);
K_val        = K_true(valIdx);

X_test_feat  = X_features(testIdx, :);
K_test       = K_true(testIdx);

%% Normalisation (mapstd) des features et de K
X_all_feat = [X_train_feat; X_val_feat; X_test_feat];
K_all      = [K_train; K_val; K_test];

[Xn_all, ps_input] = mapstd(X_all_feat');
Xn_all = Xn_all';

[Kn_all, ps_target] = mapstd(K_all');
Kn_all = Kn_all';

Ntrain = size(X_train_feat, 1);
Nval   = size(X_val_feat, 1);

Xn_train = Xn_all(1 : Ntrain, :);
Kn_train = Kn_all(1 : Ntrain);

Xn_val = Xn_all(Ntrain+1 : Ntrain+Nval, :);
Kn_val = Kn_all(Ntrain+1 : Ntrain+Nval);

Xn_test = Xn_all(Ntrain+Nval+1 : end, :);
Kn_test = Kn_all(Ntrain+Nval+1 : end);

if strcmp(mode, "predict")
    % Pas de split, tout le dataset pour l'estimation
    Xn_test = Xn_all;
    Kn_test = Kn_all;
end

%% Définition et entraînement du réseau (fitnet)
model_file = 'data/models/Kfactor_estimator_global.mat';

if strcmp(mode, "train")
    hiddenSizes = [20, 10];
    net = fitnet(hiddenSizes);
    net.layers{1}.transferFcn = 'poslin';
    net.layers{2}.transferFcn = 'poslin';
    net.layers{3}.transferFcn = 'purelin';
    net.divideFcn = 'divideind';
    net.trainFcn = 'trainlm';
    net.trainParam.epochs   = 320;
    net.trainParam.max_fail = 200;

    net.divideParam.trainInd = 1 : Ntrain;
    net.divideParam.valInd   = Ntrain+1 : Ntrain+nVal;
    net.divideParam.testInd  = Ntrain+nVal+1 : Ntrain+nVal+size(Xn_test,1);

    X_train_forNet = Xn_train';
    K_train_forNet = Kn_train';

    X_val_forNet = Xn_val';
    K_val_forNet = Kn_val';

    X_test_forNet = Xn_test';
    K_test_forNet = Kn_test';

    X_all_forNet = [X_train_forNet, X_val_forNet, X_test_forNet];
    K_all_forNet = [K_train_forNet, K_val_forNet, K_test_forNet];

    mu = mean(X_train_feat, 1);
    sigma = std(X_train_feat, 0, 1);

    X_train_norm = (X_train_feat - mu) ./ sigma;
    X_test_norm  = (X_test_feat  - mu) ./ sigma;

    [net, tr] = train(net, X_all_forNet, K_all_forNet, 'showResources', 'yes');
    figure;
    semilogy(tr.perf, 'b', 'LineWidth', 2); hold on;
    semilogy(tr.vperf, 'r', 'LineWidth', 2);
    semilogy(tr.tperf, 'g', 'LineWidth', 2);
    xlabel('Epoch');
    ylabel('MSE');
    legend('Train', 'Validation', 'Test');
    title('Evolution of the MSE during training');
    grid on;
    saveas(gcf, 'MSE_vs_Epoch.png');
    close(gcf);
    

    save(model_file, 'net', 'ps_input', 'ps_target');
   % disp('Modèle sauvegardé après entraînement.');
else
    if ~exist(model_file, 'file')
        error('Aucun modèle entraîné trouvé. Lancez d''abord en mode train.');
    end
    load(model_file, 'net', 'ps_input', 'ps_target');
   % disp('Modèle chargé pour estimation seule.');
end

%% Évaluation sur l’ensemble de test
Y_pred_norm = net(Xn_test');
Y_pred      = mapstd('reverse', Y_pred_norm, ps_target)';
K_test_orig = mapstd('reverse', Kn_test', ps_target)';

rmse = sqrt(mean((Y_pred - K_test_orig).^2));
R2   = 1 - sum((Y_pred - K_test_orig).^2) / sum((K_test_orig - mean(K_test_orig)).^2);
%fprintf('Performances spectrales+statistiques : RMSE = %.4f, R2 = %.4f\n', rmse, R2);

mdl = fitlm(X_train_feat, K_train);
y_pred_lin = predict(mdl, X_test_feat);
R2_lin = 1 - sum((y_pred_lin - K_test).^2) / sum((K_test - mean(K_test)).^2);
%fprintf('Régression linéaire : R2 = %.4f\n', R2_lin);

% Scatter log/log filtré
mask = (K_test_orig > 0) & (Y_pred > 0);
K_test_orig_pos = K_test_orig(mask);
Y_pred_pos = Y_pred(mask);

fig = figure('Visible','off');
scatter(K_test_orig_pos, Y_pred_pos, 'filled');
hold on;
mi = min(K_test_orig_pos); ma = max(K_test_orig_pos);
plot([mi, ma], [mi, ma], 'r--', 'LineWidth', 1);
set(gca, 'XScale', 'log', 'YScale', 'log');
xlabel('K réel');
ylabel('K prédit');
title('Classification du facteur K (échelle log)');
grid on;
saveas(fig, 'K_prediction_global.png');
close(fig);

% Données filtrées
K_real = K_test_orig_pos;
K_pred = Y_pred_pos;

% Définition des bornes pour l'échelle log
mi = min([K_real; K_pred]);
ma = max([K_real; K_pred]);

% Logarithmes des données
logK_real = log10(K_real);
logK_pred = log10(K_pred);

% Définition des bins
nbins = 100;  % à ajuster selon densité
edges = linspace(log10(mi), log10(ma), nbins+1);

% Calcul de l'histogramme 2D
[counts, Xedges, Yedges] = histcounts2(logK_real, logK_pred, edges, edges);

% Affichage
fig = figure('Visible','off');
imagesc(Xedges, Yedges, counts');  % note le transpose !
axis xy;  % origine en bas à gauche
colormap(jet); colorbar;
hold on;

% Diagonale (K_prédit = K_réel)
plot([log10(mi), log10(ma)], [log10(mi), log10(ma)], 'r--', 'LineWidth', 1);

% Mise à l’échelle des axes
xticks = log10([0.1 0.2 0.5 1]);
xticklabels = arrayfun(@(x) sprintf('%.1f', x), 10.^xticks, 'UniformOutput', false);
yticks = xticks;
yticklabels = xticklabels;
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels, ...
         'YTick', yticks, 'YTickLabel', yticklabels);

xlabel('K réel');
ylabel('K prédit');
title('Classification du facteur K (densité log-log)');
grid on;

% Sauvegarde
saveas(fig, 'K_prediction_global_density.png');
close(fig);


% CDF lissée
fig = figure('Visible','off');
hold on;
[cdf_y, cdf_x] = ecdf(Y_pred);
[unique_cdf_x, ia] = unique(cdf_x);
unique_cdf_y = cdf_y(ia);
xq = linspace(min(unique_cdf_x), max(unique_cdf_x), 500);
yq = interp1(unique_cdf_x, unique_cdf_y, xq, 'pchip');
plot(xq, yq, 'b', 'LineWidth', 2);

[cdf_y_true, cdf_x_true] = ecdf(K_test_orig);
[unique_cdf_x_true, ia_true] = unique(cdf_x_true);
unique_cdf_y_true = cdf_y_true(ia_true);
xq_true = linspace(min(unique_cdf_x_true), max(unique_cdf_x_true), 500);
yq_true = interp1(unique_cdf_x_true, unique_cdf_y_true, xq_true, 'pchip');
plot(xq_true, yq_true, 'r--', 'LineWidth', 2);

xlabel('K');
ylabel('F(K)');
legend('K prédit', 'K réel', 'Location', 'best');
title('Fonction de répartition cumulée (CDF) du facteur K (lissée)');
grid on;
saveas(fig, 'K_CDF_global.png');
close(fig);

end