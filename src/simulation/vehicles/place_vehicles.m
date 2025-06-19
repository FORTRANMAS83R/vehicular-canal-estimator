function vehicles = place_vehicles(N, v_min, v_max, d_min, d_max, x_start, lane)
    % PLACE_VEHICLES - Places vehicles along a lane with random spacing and velocities.
    %
    % Parameters:
    %   N (int): Number of vehicles.
    %   v_min, v_max (float): Minimum and maximum velocities (m/s).
    %   d_min, d_max (float): Minimum and maximum spacing between vehicles (m).
    %   x_start (float): Starting position of the first vehicle (default: 0).
    %   lane (int): Lane direction (positive or negative).
    %
    % Returns:
    %   vehicles (struct array): Array of vehicles with positions and velocities.

    if nargin < 6
        x_start = 0;  % Default starting position
    end

    vehicles(N) = struct();  % Preallocate structure array

    % Place the first vehicle
    vehicles(1).position = x_start;
    vehicles(1).velocity = [lane * (rand() * (v_max - v_min) + v_min); 0; 0];

    for i = 2:N
        % Random spacing ≥ d_min
        d = d_min + rand() * (d_max - d_min);

        % New position
        vehicles(i).position = vehicles(i-1).position + [lane * d; 0; 0];

        % Random velocity
        alpha = 1 - (i-1)/(N-1);  % Decreases from 1 to 0
        bias = v_min + alpha * (v_max - v_min);
        velocity = bias + randn() * 2;  % Add slight noise
        vehicles(i).velocity = [lane * max(min(velocity, v_max), v_min); 0; 0];  % Clamp velocity
    end
end