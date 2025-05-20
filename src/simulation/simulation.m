function simulation(json_file, varargin)
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
    addpath('src/utils');

    verbose = false;  
    for i = 1:length(varargin)
        arg = varargin{i};
        if strcmp(arg, '-v')
            verbose = true;
        end
    end
    % Check if the JSON configuration file exists
    if ~isfile(json_file)
        error('No such JSON file found: %s', json_file);
    end

    % Read and decode the JSON configuration file
    raw = fileread(json_file);
    conf = jsondecode(raw);

    % Calculate the coherence time based on the maximum Doppler shift
    T_c = (0.423 * 3e8) / (conf.vehicles.v_max * conf.emitter.f); % in seconds
    fprintf('Simulation duration: %.4f milliseconds\n', T_c * 1000);

    % Run the traffic simulation
    vehicles = simulate_traffic(conf.vehicles, conf.nb_samples, T_c);
    buildings = simulate_buildings(conf); % Combine vehicles and buildings
    [vehicles.eps_r] = deal(0.2); % Assign eps_r to all vehicles
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
    results = struct();

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
        [results(i).delay, results(i).A, results(i).f_d] = modelise_paths(Tx, Rx, s_i, conf.emitter.f);
    end
    results = keep_top_n(results, 3); 
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
            else
                fprintf('Sample %d: No result.\n', i);
            end
        end
    end

    elapsed_time = toc; % Stop timing
    fprintf('\r \t DONE (%.4f seconds)\n', elapsed_time);
    
end


