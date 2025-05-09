function [p, v, a] = lane_manager(traffic_params, spawn_range, vehicule_step, nb_vehicules, n_samples)
    % LANE_MANAGER - Simulates traffic for a single lane.
    %
    % Parameters:
    %   traffic_params (struct): Traffic configuration parameters.
    %   spawn_range (array): [start, end, y-coordinate] spawn range for vehicles.
    %   vehicule_step (float): Step size for vehicle positions.
    %   nb_vehicules (int): Number of vehicles in the lane.
    %   n_samples (int): Number of simulation samples.
    %
    % Returns:
    %   p (array): Positions of vehicles [(x, y), vehicle index, sample index].
    %   v (array): Velocities of vehicles [(x, y), vehicle index, sample index].
    %   a (array): Accelerations of vehicles [(x, y), vehicle index, sample index].

    % Extract traffic parameters
    v_min = traffic_params.velocity.minimum; % Minimum velocity (m/s)
    v_max = traffic_params.velocity.maximum; % Maximum velocity (m/s)
    a_min = traffic_params.acceleration.minimum; % Minimum acceleration (m/s²)
    a_max = traffic_params.acceleration.maximum; % Maximum acceleration (m/s²)
    d_cible = traffic_params.distance.target; % Target distance between vehicles (m)
    dt = traffic_params.dt; % Time step (s)

    % Generate possible initial positions
    i = 0:fix(abs(spawn_range(2) - spawn_range(1)) / vehicule_step) - 1;
    possible_positions = spawn_range(1) + vehicule_step * i; 
    if size(possible_positions, 2) < nb_vehicules
        error('Not enough space to spawn the vehicles');
    end
    initial_positions = randsample(possible_positions, nb_vehicules);
    initial_positions = sort(initial_positions); % Sort initial positions
    initial_positions = [initial_positions; spawn_range(3) * ones(1, nb_vehicules)]; % Add y-coordinate

    % Generate initial velocities and accelerations
    initial_velocity = v_min + rand(1, nb_vehicules) * (v_max - v_min); 
    initial_velocity = [initial_velocity; zeros(1, nb_vehicules)];
    initial_acceleration = a_min + rand(1, nb_vehicules) * (a_max - a_min);
    initial_acceleration = [initial_acceleration; zeros(1, nb_vehicules)];

    % Initialize position, velocity, and acceleration arrays
    p = spawn_range(3) * ones(2, nb_vehicules, n_samples); 
    v = zeros(2, nb_vehicules, n_samples);      
    a = zeros(2, nb_vehicules, n_samples);

    % Set initial conditions
    p(:, :, 1) = initial_positions;
    v(:, :, 1) = initial_velocity;
    a(:, :, 1) = initial_acceleration;

    % Randomize velocities and accelerations for simulation
    v(1, :, :) = v_min + rand(nb_vehicules, n_samples) * (v_max - v_min); 
    a(1, :, :) = a_min + rand(nb_vehicules, n_samples) * (a_max - a_min);  

    % Simulate traffic for each sample
    for i = 1:n_samples 
        if i > 1 
            % Update position for the last vehicle
            p(1, nb_vehicules, i) = p(1, nb_vehicules, i-1) + ...
                v(1, nb_vehicules, i-1) * dt + 0.5 * a(1, nb_vehicules, i-1) * dt^2;
        end 
        for j = nb_vehicules-1:-1:1             
            % Update velocity and acceleration adaptively
            [v_new, a_i] = update_vitesse_adaptatif( ...
                p(1, j+1, i), v(1, j+1, i), ...
                p(1, j, i), v(1, j, i), ...
                d_cible, dt ...
            ); 
            v(1, j, i) = v_new; % Update velocity for vehicle j
            a(1, j, i) = a_i;   % Update acceleration for vehicle j
            if i > 1 
                % Update position for vehicle j
                p(1, j, i) = p(1, j, i-1) + ...
                    v(1, j, i-1) * dt + 0.5 * a(1, j, i-1) * dt^2;
            end
        end
    end 
end