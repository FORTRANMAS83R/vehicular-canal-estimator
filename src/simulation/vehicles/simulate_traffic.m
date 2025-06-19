function vehicles = simulate_traffic(conf, nb_samples, T_c)
    
    % SIMULATE_TRAFFIC - Simulates traffic for two lanes.
    %
    % Parameters:
    %   v_min, v_max (float): Minimum and maximum velocities (m/s).
    %   a_min, a_max (float): Minimum and maximum accelerations (m/s^2).
    %   d_cible (float): Target distance between vehicles (m).
    %   dt (float): Time step for the simulation (s).
    %   spawn_range_1, spawn_range_2 (arrays): Spawn ranges for lanes 1 and 2.
    %   vehicule_step_1, vehicule_step_2 (float): Step size for vehicle positions in lanes 1 and 2.
    %   nb_vehicules_1, nb_vehicules_2 (int): Number of vehicles in lanes 1 and 2.
    %   nb_samples (int): Number of simulation samples.
    %
    % Returns:
    %   p1, v1, a1 (arrays): Position, velocity, and acceleration for lane 1.
    %   p2, v2, a2 (arrays): Position, velocity, and acceleration for lane 2.

    fprintf('Starting traffic simulation... \n');
    tic; % Start timing the simulation

    % Set traffic parameters
    
    vehicles_1 = place_vehicles(conf.nb_vehicles, conf.v_min, conf.v_max, conf.d_min, conf.d_max, conf.initial_pos(1, :).', 1);
    vehicles_2 = place_vehicles(conf.nb_vehicles, conf.v_min, conf.v_max, conf.d_min, conf.d_max, conf.initial_pos(2, :).', -1);

    vehicles = [vehicles_1, vehicles_2]; % Combine vehicles from both lanes
    
    vehicles = simulate_positions(vehicles, nb_samples, T_c); % Simulate positions
    elapsed_time = toc; % Stop timing
    fprintf('\r \t DONE (%.4f seconds)\n', elapsed_time);
end