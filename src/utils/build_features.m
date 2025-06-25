function build_features(varargin)
% Wrapper to build features from .h5 files.
% By default, input is 'data/samples' (folder).
% Use -input <folder_or_file> and/or -output <output_file> in varargin.

% Default values
input = 'data/samples';
output_file = 'data/all_features_new.mat';

% Parse varargin for -input and -output options
i = 1;
while i <= length(varargin)
    if ischar(varargin{i})
        if strcmp(varargin{i}, '-input')
            if i < length(varargin)
                input = varargin{i+1};
                i = i + 2;
                continue;
            else
                error('Missing value after -input');
            end
        elseif strcmp(varargin{i}, '-output')
            if i < length(varargin)
                output_file = varargin{i+1};
                i = i + 2;
                continue;
            else
                error('Missing value after -output');
            end
        end
    end
    i = i + 1;
end

% Determine if input is a directory or a file
if isfolder(input)
    files = dir(fullfile(input, '*.h5'));
    filelist = fullfile({files.folder}, {files.name});
elseif isfile(input)
    filelist = {input};
else
    error('Input must be a folder or a .h5 file');
end

all_features = [];
all_K = [];

for f = 1:length(filelist)
    h5_filename = filelist{f};
    info = h5info(h5_filename);
    datasets = {info.Datasets.Name};
    real_idx = find(contains(datasets, '_real'));
    N = numel(real_idx);

    first_real = h5read(h5_filename, sprintf('/sample_%d_real', 1));
    M = numel(first_real);
    X = zeros(N, M);
    K_true = zeros(N, 1);

    for i = 1:N
        real_part = h5read(h5_filename, sprintf('/sample_%d_real', i));
        imag_part = h5read(h5_filename, sprintf('/sample_%d_imag', i));
        X(i, :) = (real_part + 1i * imag_part).';
        K_true(i) = h5read(h5_filename, sprintf('/sample_%d_K', i));
    end

    % Feature extraction (same as estimate_K_factor)
    energy   = sum(abs(X).^2, 2);
    powerAvg = energy / M;
    varTime  = var(abs(X), 0, 2);
    skewTime = skewness(abs(X), 0, 2);
    kurtTime = kurtosis(abs(X), 0, 2);
    maxAbs   = max(abs(X), [], 2);
    medianAbs= median(abs(X), 2);
    p25      = prctile(abs(X), 25, 2);
    p75      = prctile(abs(X), 75, 2);

    p = 20;
    halfM = floor(M/2);
    X_fft = fft(X, [], 2);
    X_mag = abs(X_fft(:,1:halfM));
    if p > halfM
        error('p must be <= M/2.');
    end
    X_spec = X_mag(:, 1:p);

    X_features = [energy, powerAvg, varTime, skewTime, kurtTime, maxAbs, medianAbs, p25, p75, X_spec];

    all_features = [all_features; X_features];
    all_K = [all_K; K_true];
end

save(output_file, 'all_features', 'all_K');
fprintf('Features and K saved to %s\n', output_file);
end