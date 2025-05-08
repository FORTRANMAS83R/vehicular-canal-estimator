function [p, v, a] = lane_manager(traffic_params, spawn_range, vehicule_step, nb_vehicules, n_samples)
    %Setting up the parameters for the simulation
    v_min = traffic_params.velocity.minimum; % Vitesse minimale (m/s)
    v_max = traffic_params.velocity.maximum; % Vitesse maximale (m/s)
    a_min = traffic_params.acceleration.minimum; % Accélération minimale (m/s²)
    a_max = traffic_params.acceleration.maximum; % Accélération maximale (m/s²)
    d_cible = traffic_params.distance.target; % Distance cible (m)
    dt = traffic_params.dt; % Pas de temps (s)

    i = 0:fix(abs(spawn_range(2) - spawn_range(1)) / vehicule_step) - 1;
    possible_positions = spawn_range(1) + vehicule_step*i; 
    initial_positions = randsample(possible_positions, nb_vehicules);
    
    initial_positions = sort(initial_positions); % Tri des positions initiales
    initial_positions = [initial_positions; spawn_range(3) * ones(1, nb_vehicules)]; 

    initial_velocity = v_min + rand(1, nb_vehicules) * (v_max - v_min); 
    initial_velocity = [initial_velocity; zeros(1, nb_vehicules)];

    initial_acceleration = a_min + rand(1, nb_vehicules) * (a_max - a_min);
    initial_acceleration = [initial_acceleration; zeros(1, nb_vehicules)];

    
    p = spawn_range(3) * ones(2, nb_vehicules, n_samples); 
    v = zeros(2, nb_vehicules, n_samples);      
    a = zeros(2, nb_vehicules, n_samples);


    % p, v, a  [(x,y), vehicule index, sample index]
    p(:, :, 1) = initial_positions;
    v(:, :, 1) = initial_velocity;
    a(:, :, 1) = initial_acceleration;

    v(1,:, :) = v_min + rand(nb_vehicules, n_samples) * (v_max - v_min); 
    a(1,:, :) =  a_min + rand(nb_vehicules, n_samples) * (a_max - a_min);  

    for i = 1:n_samples 
        if i > 1 
            p(1, nb_vehicules, i) = p(1, nb_vehicules, i-1) + v(1, nb_vehicules, i-1) * dt + 1/2 * a(1, nb_vehicules, i-1) * dt^2;
        end 
        for j = nb_vehicules-1:-1:1             
            [v_new, a_i] = update_vitesse_adaptatif(p(1, j+1, i), v(1, j+1, i), p(1, j, i), v(1, j, i), d_cible, dt); 
            v(1, j, i) = v_new; % Mise à jour de la vitesse du véhicule j
            a(1, j, i) = a_i; % Mise à jour de l'accélération du véhicule j 
            if i > 1 
                p(1, j, i) = p(1, j, i-1) + v(1, j, i-1) * dt + 1/2 * a(1, j, i-1) * dt^2; % Mise à jour de la position du véhicule j
            end
        end
    end 
    end 