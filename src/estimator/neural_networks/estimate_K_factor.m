% filepath: c:\code\liu\vehicular-canal-estimator\src\estimator\neural_networks\estimate_K_factor.m
%
% estimate_K_factor - Train or evaluate a neural network for Rice K-factor estimation.
%
% Syntax:
%   [rmse, R2, R2_lin] = estimate_K_factor(mat_filename)
%   [rmse, R2, R2_lin] = estimate_K_factor(mat_filename, mode)
%
% Description:
%   This function trains or evaluates a feedforward neural network to estimate the Rice K-factor
%   from a set of features. The function supports both training and prediction modes.
%   - In 'train' mode (default), the function normalizes the features and targets, splits the data
%     into training, validation, and test sets, trains the network, and saves the model and normalization parameters.
%   - In 'predict' mode, the function loads the trained model and normalization parameters, applies them to the input
%     features, and predicts the K-factor.
%
% Inputs:
%   mat_filename : string
%       Path to a .mat file containing:
%           - all_features : [N x F] matrix of features (N samples, F features)
%           - all_K       : [N x 1] vector of true K-factor values (linear scale)
%   mode         : string (optional)
%       'train'   - Train the neural network (default)
%       'predict' - Predict using a previously trained model
%
% Outputs:
%   rmse   : double
%       Root Mean Squared Error between predicted and true K-factor values.
%   R2     : double
%       Coefficient of determination (R²) for the neural network predictions.
%   R2_lin : double
%       Coefficient of determination (R²) for a linear regression baseline.
%
% Side Effects:
%   - Saves normalization parameters to 'data/models/Kfactor_norm_params.mat'
%   - Saves the trained neural network to 'data/models/Kfactor_estimator_global.mat'
%   - Generates and saves three figures:
%       - 'K_prediction_global.png' : log-log scatter plot of true vs predicted K-factor
%       - 'K_prediction_global_density.png' : density plot of true vs predicted K-factor
%       - 'K_CDF_global.png'    : CDF comparison of true and predicted K-factor
%
% Example:
%   % Train the model
%   [rmse, R2, R2_lin] = estimate_K_factor('data/all_features.mat', 'train');
%
%   % Predict on new data
%   [rmse, R2, R2_lin] = estimate_K_factor('data/new_features.mat', 'predict');
%
% Notes:
%   - The K-factor is estimated in log10 scale for improved numerical stability.
%   - The function uses mapstd for normalization and fitnet (MATLAB Neural Network Toolbox) for regression.
%   - The neural network architecture is [20, 10] hidden neurons with ReLU activation.
%   - The function also computes the performance of a linear regression baseline for comparison.
%
% Author: Mikael Franco
%

function [rmse, R2, R2_lin] = estimate_K_factor(mat_filename, mode)
warning('off','all'); % Disable all warnings

if nargin < 2
    mode = "train"; % Default mode is 'train'
end

% Load features and true K-factor values from .mat file
data = load(mat_filename, 'all_features', 'all_K');
X_features = data.all_features; % Feature matrix [N x F]
K_true = data.all_K;           % True K-factor vector [N x 1]
N = size(X_features, 1);       % Number of samples

%% Random split into train/val/test sets
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

%% Feature and target normalization (mapstd)
X_all_feat = [X_train_feat; X_val_feat; X_test_feat];
K_all      = [K_train; K_val; K_test];

[Xn_all, ps_input] = mapstd(X_all_feat'); % Normalize features
Xn_all = Xn_all';

[Kn_all, ps_target] = mapstd(K_all');     % Normalize targets
Kn_all = Kn_all';

Ntrain = size(X_train_feat, 1);
Nval   = size(X_val_feat, 1);

Xn_train = Xn_all(1 : Ntrain, :);
Kn_train = Kn_all(1 : Ntrain);

Xn_val = Xn_all(Ntrain+1 : Ntrain+Nval, :);
Kn_val = Kn_all(Ntrain+1 : Ntrain+Nval);

Xn_test = Xn_all(Ntrain+Nval+1 : end, :);
Kn_test = Kn_all(Ntrain+Nval+1 : end);

% File to save/load normalization parameters
norm_file = 'data/models/Kfactor_norm_params.mat';

if strcmp(mode, "train")
    % Save normalization parameters for later use
    save(norm_file, 'ps_input', 'ps_target');
elseif strcmp(mode, "predict")
    % Load normalization parameters from training
    if exist(norm_file, 'file')
        S = load(norm_file, 'ps_input', 'ps_target');
        ps_input = S.ps_input;
        ps_target = S.ps_target;
    else
        error('Normalization parameters not found. Run in train mode first.');
    end
    % Normalize current features using training parameters
    Xn_all = mapstd('apply', X_features', ps_input)';
    K_all  = mapstd('apply', K_true', ps_target)';
    Xn_test = Xn_all;
    Kn_test = K_all;
end

%% Define and train the neural network (fitnet)
model_file = 'data/models/Kfactor_estimator_global.mat';

if strcmp(mode, "train")
    hiddenSizes = [20, 10]; % Two hidden layers
    net = fitnet(hiddenSizes);
    net.layers{1}.transferFcn = 'poslin'; % ReLU
    net.layers{2}.transferFcn = 'poslin';
    net.layers{3}.transferFcn = 'purelin'; % Linear output
    net.divideFcn = 'divideind';
    net.trainFcn = 'trainlm'; % Levenberg-Marquardt
    net.trainParam.epochs   = 320;
    net.trainParam.max_fail = 200;

    net.divideParam.trainInd = 1 : Ntrain;
    net.divideParam.valInd   = Ntrain+1 : Ntrain+nVal;
    net.divideParam.testInd  = Ntrain+nVal+1 : nTrain+nVal+size(Xn_test,1);

    X_train_forNet = Xn_train';
    K_train_forNet = Kn_train';

    X_val_forNet = Xn_val';
    K_val_forNet = Kn_val';

    X_test_forNet = Xn_test';
    K_test_forNet = Kn_test';

    X_all_forNet = [X_train_forNet, X_val_forNet, X_test_forNet];
    K_all_forNet = [K_train_forNet, K_val_forNet, K_test_forNet];

    % Train the neural network
    [net, tr] = train(net, X_all_forNet, K_all_forNet, 'showResources', 'yes');
    
    % Plot MSE evolution during training
    figure;
    semilogy(tr.perf, 'b', 'LineWidth', 2); hold on;
    semilogy(tr.vperf, 'r', 'LineWidth', 2);
    semilogy(tr.tperf, 'g', 'LineWidth', 2);
    xlabel('Epoch');
    ylabel('MSE');
    legend('Train', 'Validation', 'Test');
    title('MSE Evolution During Training');
    grid on;
    saveas(gcf, 'MSE_vs_Epoch.png');
    close(gcf);

    % Save the trained model and normalization parameters
    save(model_file, 'net', 'ps_input', 'ps_target');
else
    % Load trained model and normalization parameters
    if ~exist(model_file, 'file')
        error('No trained model found. Run in train mode first.');
    end
    load(model_file, 'net', 'ps_input', 'ps_target');
end

%% Evaluate on the test set
Y_pred_norm = net(Xn_test');
Y_pred      = mapstd('reverse', Y_pred_norm, ps_target)'; % Denormalize predictions
K_test_orig = mapstd('reverse', Kn_test', ps_target)';    % Denormalize targets

rmse = sqrt(mean((Y_pred - K_test_orig).^2)); % RMSE
R2   = 1 - sum((Y_pred - K_test_orig).^2) / sum((K_test_orig - mean(K_test_orig)).^2); % R²

% Linear regression baseline
mdl = fitlm(X_train_feat, K_train);
y_pred_lin = predict(mdl, X_test_feat);
R2_lin = 1 - sum((y_pred_lin - K_test).^2) / sum((K_test - mean(K_test)).^2);

% Scatter plot log/log (filtered)
mask = (K_test_orig > 0) & (Y_pred > 0);
K_test_orig_pos = K_test_orig(mask);
Y_pred_pos = Y_pred(mask);

fig = figure('Visible','off');
scatter(K_test_orig_pos, Y_pred_pos, 'filled');
hold on;
mi = min(K_test_orig_pos); ma = max(K_test_orig_pos);
plot([mi, ma], [mi, ma], 'r--', 'LineWidth', 1);
set(gca, 'XScale', 'log', 'YScale', 'log');
xlabel('True K-factor');
ylabel('Predicted K-factor');
title('K-factor Regression (log-log scale)');
grid on;
saveas(fig, 'K_prediction_global.png');
close(fig);

% Filtered data for density plot
K_real = K_test_orig_pos;
K_pred = Y_pred_pos;

% Define bounds for log scale
mi = min([K_real; K_pred]);
ma = max([K_real; K_pred]);

% Logarithms of the data
logK_real = log10(K_real);
logK_pred = log10(K_pred);

% Define bins
nbins = 100;
edges = linspace(log10(mi), log10(ma), nbins+1);

% 2D histogram
[counts, Xedges, Yedges] = histcounts2(logK_real, logK_pred, edges, edges);

% Density plot
fig = figure('Visible','off');
imagesc(Xedges, Yedges, counts');
axis xy;
colormap(jet); colorbar;
hold on;
plot([log10(mi), log10(ma)], [log10(mi), log10(ma)], 'r--', 'LineWidth', 1);

xticks = log10([0.1 0.2 0.5 1]);
xticklabels = arrayfun(@(x) sprintf('%.1f', x), 10.^xticks, 'UniformOutput', false);
yticks = xticks;
yticklabels = xticklabels;
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels, ...
         'YTick', yticks, 'YTickLabel', yticklabels);

xlabel('True K-factor');
ylabel('Predicted K-factor');
title('K-factor Regression Density (log-log)');
grid on;
saveas(fig, 'K_prediction_global_density.png');
close(fig);

% Smoothed CDF
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

xlabel('K-factor');
ylabel('F(K)');
legend('Predicted K-factor', 'True K-factor', 'Location', 'best');
title('Cumulative Distribution Function (CDF) of K-factor (smoothed)');
grid on;
saveas(fig, 'K_CDF_global.png');
close(fig);

end
