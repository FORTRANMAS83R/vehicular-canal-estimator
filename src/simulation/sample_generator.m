function sample_generator(varargin)
    addpath('src/simulation/emitter');
    addpath('src/simulation/channel');
    num_paths = 4; 
    num_samples  = 1000; 

    d_min = 10;  % Distance minimale (m)
    d_max = 100; 
    min_f_d = -1500;
    max_f_d = 1500;
    raw = fileread("src/simulation/config/config_new.json");
    conf = jsondecode(raw);
    tick = tic;  % Start the timer for performance measurement
    c = 3e8;  % Vitesse de la lumière (m/s)
    signal_tx = cell(num_samples, 1);  % Initialisation du signal transmis
    signal_rx = cell(num_samples, 1);  % Initialisation du signal reçu
    T_c = (40 / conf.vehicles.v_max) * (3e8 / conf.emitter.params.fc); % in seconds

    eps_cible = 0.001; 
    alpha = 10^3;
    SNR = [20, 15, 10, 5, 0];
    N = alpha / ( 10^(min(SNR)/10) * eps_cible ); 
    N = 1000; 
    disp(N)
    conf.emitter.params.fs = N / T_c; 
    SNR = [20, 15, 10, 5, 0];

    for j = 1: numel(SNR)
        fprintf('\nCréation des samples avec un SNR de %d dB\n', SNR(j));
        sample(num_samples) = struct('SNR', [], 'K', [], 'signal_rx', []);
        for i = 1:num_samples
            sample(i).SNR = SNR(j);  % Assign SNR for each sample
            distance = d_min + (d_max - d_min) * rand(num_paths, 1);
            delays = distance / c;  % délais en secondes
            theta = -pi / 2 + pi * rand(num_paths, 1); 
            A_el = -20 * log10(distance) - 20 * log10(conf.emitter.params.fc) - 20 * log10(4 * pi / c);
            eps_r = conf.buildings.eps_r + randi([0 1], num_paths, 1) * 10^3;  % Permittivité relative
            sig_te = (cosd(theta) - sqrt(eps_r - sind(theta).^2)) ./ (cosd(theta) + sqrt(eps_r - sind(theta).^2));
            sig_tm = (eps_r .* cosd(theta) - sqrt(eps_r - sind(theta).^2)) ./ (eps_r .* cosd(theta) + sqrt(eps_r - sind(theta).^2));
            sig = 1/2 * (abs(sig_te).^2 + abs(sig_tm).^2);
            A = A_el - 20 * log10(sig);  % Atténuation en dB

            P = 10.^(A/10);         % Puissance linéaire pour chaque trajet
            P_los = max(P);         % On suppose que le LOS est le plus puissant
            P_nlos = sum(P) - P_los; % Puissance totale des NLOS

            K = P_los / P_nlos;     % K factor linéaire
            K_dB = 10*log10(K);     % K factor en dB
            sample(i).K = K; 

            f_d =  min_f_d + (max_f_d - min_f_d) * rand(num_paths, 1);  % Doppler shifts
            signal_tx{i} = generate_signal(i, conf.emitter.modulation_type, conf.emitter.params, T_c);
            [sample(i).signal_rx, ~] = simulate_rician_rx(signal_tx{i}.waveform, ...
                A,...
                f_d,...
                theta,...
                K,...
                num_paths,...
                delays,...
                conf.emitter.params.fs);
            % Ajout du bruit
            sample(i).signal_rx = awgn(sample(i).signal_rx, SNR(j));  

            % Affichage barre de progression
            if mod(i, round(num_samples/100)) == 0 || i == num_samples
                fprintf('\rProgression : %d/%d', i, num_samples);
            end
        end
        fprintf(' - completed\n'); % Fin de la barre de progression

        h5_filename = sprintf('data/sample_SNR_%ddB.h5', SNR(j));
        if exist(h5_filename, 'file')
            delete(h5_filename); % Supprime l'ancien fichier s'il existe
        end
        for k = 1:num_samples
            dataset_name_real = sprintf('/sample_%d/signal_rx_real', k);
            dataset_name_imag = sprintf('/sample_%d/signal_rx_imag', k);
            data = sample(k).signal_rx;
            % Enregistre la partie réelle
            h5create(h5_filename, dataset_name_real, size(real(data)));
            h5write(h5_filename, dataset_name_real, real(data));
            % Enregistre la partie imaginaire
            h5create(h5_filename, dataset_name_imag, size(imag(data)));
            h5write(h5_filename, dataset_name_imag, imag(data));
            % Enregistre aussi le K factor
            h5create(h5_filename, sprintf('/sample_%d/K', k), 1);
            h5write(h5_filename, sprintf('/sample_%d/K', k), sample(k).K);
        end
        fprintf('Structure enregistrée dans %s\n', h5_filename);
    end 
    elapsed_time = toc(tick);  % Stop the timer
    fprintf('\r \t DONE (%.4f seconds)\n', elapsed_time);
end