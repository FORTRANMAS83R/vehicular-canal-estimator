
function model_traj_LM(p_0, vel_inf, vel_sup, acc_inf, acc_sup, T, dt)
    % Model the trajectory of a car using a linear model with constant acceleration
    % p_0: initial position (m)
    % vel_inf: minimum velocity (m/s)
    % vel_sup: maximum velocity (m/s)
    % acc_inf: minimum acceleration (m/s^2)
    % acc_sup: maximum acceleration (m/s^2)
    % T: total simulation time (s)
    % dt: time step (s)
    t = 0:dt:T;
    a_0 = round ((acc_inf + (acc_sup - acc_inf) * rand())*10) / 10;
    v_0 = round ((vel_inf + (vel_sup - vel_inf) * rand())*10) / 10;
    v = v_0 + a_0 * t;
    p = p_0 + v_0 * t + 1/2 * a_0 * t .^ 2;  
end 

function [p1, v1, a1, p2, v2, a2 ] = traffic_manager(traffic_params, spawn_range, vehicule_step, nb_vehicules, nb_samples, dt)
    [p1, v1, a1] = lane_manager(traffic_params, spawn_range{1}, vehicule_step(1), nb_vehicules(1), nb_samples);
    [p2, v2, a2] = lane_manager(traffic_params, spawn_range{2}, vehicule_step(2), nb_vehicules(2), nb_samples);
end 






%lane_manager([0, 100], 5, 10, 13, 1); % Exemple d'appel de la fonction


 disp(p2)



function [v_new, a_i] = update_vitesse_adaptatif(pos_i, v_i, pos_j, v_j, d_cible, dt)
    % Entrées :
    %   pos_i, v_i : position et vitesse du véhicule i (suiveur)
    %   pos_j, v_j : position et vitesse du véhicule i+1 (leader)
    %   d_cible    : distance de sécurité à maintenir
    %   dt         : pas de temps (en secondes)
    %
    % Sorties :
    %   v_new : vitesse mise à jour du véhicule i
    %   a_i   : accélération appliquée (m/s²)
    
    % Paramètres du régulateur adaptatif
    Kp = 0.5;     % gain sur la distance
    Kv = 1.0;     % gain sur la vitesse relative
    a_max = 2.5;  % accélération max (en m/s²)
    v_max = 30;   % vitesse max
    v_min = 0;    % vitesse minimale (arrêt)
    
    % Calcul de la distance et de la différence de vitesse
    d = norm(pos_j - pos_i);       % distance entre i et i+1
    delta_v = v_j - v_i;           % vitesse relative (positive si leader va plus vite)
    
    % Calcul de l'accélération régulée
    a_i = Kp * (d_cible - d) + Kv * delta_v;
    a_i = max(min(a_i, a_max), -a_max);  % limitation de l'accélération
    
    % Mise à jour de la vitesse avec l'accélération
    v_new = v_i + a_i * dt;
    v_new = max(min(v_new, v_max), v_min);  % saturation entre v_min et v_max
    end
    