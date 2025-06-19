function simulation(varargin)
    % SIMULATION - Main function to run the vehicular canal simulation
    %
    % Parameters:
    %   json_file (string): Path to the JSON configuration file.
    %
    % This function reads the configuration file, calculates the coherence
    % time based on the maximum Doppler shift, and runs the traffic simulation.
    % The results are saved in an HDF5 file.

    % Add the vehicles directory to the MATLAB path
    addpath('src/simulation/vehicles');
    addpath('src/simulation/raytrace');
    addpath('src/simulation/buildings');
    addpath('src/simulation/channel');
    addpath('src/simulation/emitter');
    addpath('src/utils');

    verbose = false;  
    num_paths = 3; 
    custom_output = false;
    raw = fileread(varargin{1});
    conf = jsondecode(raw);
    for i = 2:length(varargin)
        arg = varargin{i};
        if strcmp(arg, '-v')
            verbose = true;
        end
        if strcmp(arg, '-output')
            custom_output = true;
            custom_output_file = varargin{i+1};
            fprintf('Custom output enabled.\n');
        end
        if strcmp(arg, '-snr')
            conf.snr = str2double(varargin{i+1});
            fprintf('SNR set to: %d dB\n', conf.snr);
        end
        if strcmp(arg, '-h')
            fprintf('Usage: simulation(json_file) [-v]\n');
            fprintf('Options:\n');
            fprintf('  -v : Verbose mode\n');
            fprintf('  -h : Help\n');
            return;
        end
        if strcmp(arg, '-num_paths')
            num_paths = str2double(varargin{i+1});
            fprintf('Number of paths: %d\n', num_paths);
        end
    end
    % Check if the JSON configuration file exists
    if ~isfile(varargin{1})
        error('No such JSON file found: %s', json_file);
    end

    % Read and decode the JSON configuration file


    % Calculate the coherence time based on the maximum Doppler shift
    T_c = (40 / conf.vehicles.v_max) * (3e8 / conf.emitter.params.fc); % in seconds

    eps_cible = 0.001; 
    alpha = 10^3;
    N = alpha / ( 10^(conf.snr/10) * eps_cible ); 
    N = 1000; % Number of samples
    conf.emitter.params.fs = abs(N / T_c); 
    fprintf('Sampling frequency: %.2f Hz\n', conf.emitter.params.fs);


    fprintf('Simulation duration: %.4f milliseconds\n', T_c * 1000);
    fprintf('Number of samples for the estimation: %d\n', N);

    % Run the traffic simulation
    vehicles = simulate_traffic(conf.vehicles, conf.nb_samples, T_c);
    fprintf("Vehicles générés : %d\n", numel(vehicles));
    buildings = simulate_buildings(conf); % Combine vehicles and buildings

    [vehicles.eps_r] = deal(1e5); % Assign eps_r to all vehicles
    points = [vehicles, buildings];
    disp('Starting raytracing...');

    % Always create 3 x nb_samples arrays for positions and velocities
    if isscalar(conf.antenna.tx.position)
        tx_positions = vehicles(conf.antenna.tx.position).position;   % 3 x nb_samples
        tx_velocities = vehicles(conf.antenna.tx.position).velocity;  % 3 x nb_samples
    else
        tx_positions = repmat(conf.antenna.tx.position, 1, conf.nb_samples); % 3 x nb_samples
        tx_velocities = repmat(conf.antenna.tx.velocity, 1, conf.nb_samples);
    end

    if isscalar(conf.antenna.rx.position)
        rx_positions = vehicles(conf.antenna.rx.position).position;
        rx_velocities = vehicles(conf.antenna.rx.position).velocity;
    else
        rx_positions = repmat(conf.antenna.rx.position, 1, conf.nb_samples);
        rx_velocities = repmat(conf.antenna.rx.velocity, 1, conf.nb_samples);
    end


    nb_vehicles = conf.vehicles.nb_vehicles * size(conf.vehicles.initial_pos, 1);
    nb_buildings = size(conf.buildings.position, 1);
    disp("Nombre attendu : " + (nb_vehicles + nb_buildings));
    disp("Nombre réel : " + numel(points));
    results = struct();
    channel = cell(conf.nb_samples, 1);
    signal_tx = cell(conf.nb_samples, 1); 
    signal_rx = cell(conf.nb_samples, 1);

    parfor i = 1:conf.nb_samples
        s_i = struct();  % struct array for time i
        Tx = struct();
        Tx.position = tx_positions(:, i);
        Tx.velocity = tx_velocities(:, i);
        Rx = struct();
        Rx.position = rx_positions(:, i);
        Rx.velocity = rx_velocities(:, i);
        for k = 1:nb_vehicles + nb_buildings
            s_i(k).position = points(k).position(:, i);
            s_i(k).velocity = points(k).velocity(:, i);
            s_i(k).rectangle = points(k).rectangle(:, :, i);
            s_i(k).eps_r = points(k).eps_r;
        end
        [results(i).delay, results(i).A, results(i).f_d, results(i).K] = modelise_paths(Tx, Rx, s_i, conf.emitter.params.fc, num_paths);
    end



    if verbose
        disp('Vehicle positions and velocities:');
        for i = 1:conf.nb_samples
            fprintf('Sample %d:\n', i);
            for k = 1:nb_vehicles
                pos = points(k).position(:, i);
                vel = points(k).velocity(:, i);
                fprintf('  Vehicle %d position: [%g %g %g]\n', k, pos(1), pos(2), pos(3));
                fprintf('  Vehicle %d velocity: [%g %g %g]\n', k, vel(1), vel(2), vel(3));
            end
        end
        disp('Simulation results:');
        for i = 1:conf.nb_samples
            if isfield(results, 'delay') && ~isempty(results(i).delay)
                fprintf('Sample %d:\n', i);
                fprintf('  Delay: %s\n', mat2str(results(i).delay));
                fprintf('  Attenuation (A): %s\n', mat2str(results(i).A));
                fprintf('  Doppler shift (f_d): %s\n', mat2str(results(i).f_d));
                fprintf('  K factor: %s\n', mat2str(results(i).K));
            else
                fprintf('Sample %d: No result.\n', i);
            end
        end
    end

    elapsed_time = toc; % Stop timing
    fprintf('\r \t DONE (%.4f seconds)\n', elapsed_time);


    disp('Starting channel modeling...');
    for i = 1:conf.nb_samples
        channel{i} = create_channel(results(i).delay, results(i).A, results(i).f_d, results(i).K, conf);
        signal_tx{i} = generate_signal(i, conf.emitter.modulation_type, conf.emitter.params, T_c);
        theta = zeros(num_paths, 1); % Initialize theta to zero
         
        [signal_rx{i}, a] = simulate_rician_rx(signal_tx{i}.waveform, ...
            results(i).A,...
            results(i).f_d,...
            theta,...
            10,...
            size(results(i).K),...
            results(i).delay,...
            conf.emitter.params.fs);
        signal_rx{i} = awgn(signal_rx{i}, conf.snr, 'measured'); % Add noise to the received signal

        
            a_LOS = a(:,end);           % dernier chemin = LOS
            mu = mean(a_LOS);
            sigma2 = mean(abs(a_LOS - mu).^2);
            K_est = abs(mu)^2 / sigma2;

        %signal_rx{i} = awgn(signal_rx{i}, conf.snr, 'measured');

    end
    elapsed_time = toc; % Stop timing
        % Save received signals to HDF5 file
    [~, config_name, ~] = fileparts(varargin{1});
    if custom_output
        h5_filename = custom_output_file;
    else
        h5_filename = ['data/signal_rx_' config_name '_' num2str(conf.snr) 'dB_' num2str(num_paths) '.h5'];
    end
    if exist(h5_filename, 'file')
        delete(h5_filename); % Remove old file if it exists
    end

    for i = 1:conf.nb_samples
        dataset_name = sprintf('/sample_%d', i);
        data = signal_rx{i};
        % Sauvegarde du signal reçu (parties réelle et imaginaire si complexe)
        if ~isfloat(data)
            data = double(data); % Convert to double if needed
        end
        if ~isreal(data)
            h5create(h5_filename, [dataset_name '_real'], size(data));
            h5write(h5_filename, [dataset_name '_real'], real(data));
            h5create(h5_filename, [dataset_name '_imag'], size(data));
            h5write(h5_filename, [dataset_name '_imag'], imag(data));
        else
            h5create(h5_filename, dataset_name, size(data));
            h5write(h5_filename, dataset_name, data);
        end
        % Sauvegarde du K factor
        h5create(h5_filename, [dataset_name '_K'], 1);
        h5write(h5_filename, [dataset_name '_K'], results(i).K(end)); % K LOS ou dernier K
    end
    disp(['Saved received signals to ', h5_filename]);
    fprintf('\r \t DONE (%.4f seconds)\n', elapsed_time);


    
end


