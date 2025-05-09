function [p1, v1, a1, p2, a2, v2] = simulate_traffic(v_min, v_max, a_min, a_max, d_cible, dt, spawn_range_1, spawn_range_2, vehicule_step_1, vehicule_step_2, nb_vehicules_1, nb_vehicules_2, nb_samples)
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
    traffic_params = set_traffic_params(v_min, v_max, a_min, a_max, d_cible, dt);

    % Define spawn ranges for each lane
    spawn_range1 = [spawn_range_1(1), spawn_range_1(2), spawn_range_1(3)];
    spawn_range2 = [spawn_range_2(1), spawn_range_2(2), spawn_range_2(3)];

    % Simulate traffic for both lanes using the traffic manager
    [p1, v1, a1, p2, a2, v2] = traffic_manager( ...
        traffic_params, ...
        {spawn_range1; spawn_range2}, ...
        [vehicule_step_1, vehicule_step_2], ...
        [nb_vehicules_1, nb_vehicules_2], ...
        nb_samples, ...
        dt ...
    );

    % Display elapsed time
    elapsed_time = toc; % Stop timing
    fprintf('\r \t DONE (%.4f seconds)\n', elapsed_time);
end