function [v_new, a_i] = update_vitesse_adaptatif(pos_i, v_i, pos_j, v_j, d_cible, dt)
    % UPDATE_VITESSE_ADAPTATIF - Updates the velocity and acceleration of a vehicle.
    %
    % Parameters:
    %   pos_i (float): Position of the follower vehicle.
    %   v_i (float): Velocity of the follower vehicle.
    %   pos_j (float): Position of the leader vehicle.
    %   v_j (float): Velocity of the leader vehicle.
    %   d_cible (float): Target safety distance to maintain.
    %   dt (float): Time step (in seconds).
    %
    % Returns:
    %   v_new (float): Updated velocity of the follower vehicle.
    %   a_i (float): Applied acceleration (m/s²).

    % Adaptive controller parameters
    Kp = 0.5;     % Gain on the distance
    Kv = 1.0;     % Gain on the relative velocity
    a_max = 2.5;  % Maximum acceleration (m/s²)
    v_max = 30;   % Maximum velocity
    v_min = 0;    % Minimum velocity (stop)

    % Calculate the distance and relative velocity
    d = norm(pos_j - pos_i);       % Distance between follower and leader
    delta_v = v_j - v_i;           % Relative velocity (positive if leader is faster)

    % Calculate regulated acceleration
    a_i = Kp * (d_cible - d) + Kv * delta_v;
    a_i = max(min(a_i, a_max), -a_max);  % Limit acceleration to the range [-a_max, a_max]

    % Update velocity with the calculated acceleration
    v_new = v_i + a_i * dt;
    v_new = max(min(v_new, v_max), v_min);  % Clamp velocity between v_min and v_max
end
