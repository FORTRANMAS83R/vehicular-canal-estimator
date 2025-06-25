% filepath: c:\code\liu\vehicular-canal-estimator\src\features\build_features.m
%
% build_features - Extracts features from received signal samples for K-factor estimation.
%
% Syntax:
%   [features, K] = build_features(h5_filename)
%
% Description:
%   This function reads received signal samples from an HDF5 file and computes a set of features
%   for each sample, intended for use in K-factor estimation or machine learning. Features may include
%   statistical moments, cumulants, or other descriptors of the signal amplitude distribution.
%
% Inputs:
%   h5_filename : string
%       Path to the HDF5 file containing received signal samples and K-factor values.
%
% Outputs:
%   features : [N x F] matrix
%       Feature matrix, where N is the number of samples and F is the number of features extracted.
%   K        : [N x 1] vector
%       True K-factor values for each sample (as stored in the HDF5 file).
%
% Notes:
%   - The function assumes each sample is stored as '/sample_i_real', '/sample_i_imag', and '/sample_i_K'.
%   - Feature extraction can be adapted to include higher-order moments, cumulants, or other statistics.
%   - The output can be saved to a .mat file for further processing or model training.
%
% Author: Mikael Franco
%

function [features, K] = build_features(h5_filename)
    info = h5info(h5_filename);
    num_samples = sum(contains({info.Datasets.Name}, '_real'));
    features = [];
    K = zeros(num_samples, 1);

    for i = 1:num_samples
        real_part = h5read(h5_filename, sprintf('/sample_%d_real', i));
        imag_part = h5read(h5_filename, sprintf('/sample_%d_imag', i));
        r = sqrt(real_part.^2 + imag_part.^2);

        % Example features: mean, variance, skewness, kurtosis
        mu = mean(r);
        sigma2 = var(r);
        skew = skewness(r);
        kurt = kurtosis(r);

        % Add more features as needed
        feat = [mu, sigma2, skew, kurt];
        features = [features; feat];

        % Read true K-factor
        K(i) = h5read(h5_filename, sprintf('/sample_%d_K', i));
    end