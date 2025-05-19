function vehicles = simulate_positions(vehicles, N, dt)
    % SIMULATE_POSITIONS - Simulates the positions of vehicles over time.
    %
    % Parameters:
    %   vehicles (struct array): Array of vehicles with initial positions and velocities.
    %   N (int): Number of time steps.
    %   dt (float): Time step duration (seconds).
    %
    % Returns:
    %   vehicles (struct array): Updated vehicles with simulated positions and velocities.
    length = 2; 
    height = 1; 
    for i = 1:numel(vehicles)
        x0 = vehicles(i).position;   % Initial position (3x1)
        v = vehicles(i).velocity;    % Velocity (3x1)

        t = (0:N-1) * dt;            % Time vector (1xN)
        x = x0 + v * t;              % Calculate positions (broadcasting → 3xN)

        vehicles(i).position = x; 
        x_min = vehicles(i).position(1,:)-length/2; 
        x_max = vehicles(i).position(1,:)+length/2;
        y_min = vehicles(i).position(2,:);
        y_max = vehicles(i).position(2,:);    
        z_min = vehicles(i).position(3,:); 
        z_max = vehicles(i).position(3,:)+height;
        rectangles = zeros(3,4,N);
        for n = 1:N
            rectangles(:,:,n) = [ ...
                x_min(n) x_max(n) x_max(n) x_min(n); ...
                y_min(n) y_min(n) y_max(n) y_max(n); ...
                z_min(n)    z_min(n)    z_max(n)    z_max(n) ...
            ];
        end
        vehicles(i).rectangle = rectangles;      % Update positions (3xN)
        vehicles(i).velocity = repmat(v, 1, N);  % Constant velocity (3xN)
    end
end

