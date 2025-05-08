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
    