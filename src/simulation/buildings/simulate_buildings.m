function points = simulate_buildings(conf)
    % SIMULATE_BUILDINGS - Generates building points for the simulation.
    %
    % Parameters:
    %   conf (struct): Configuration structure containing building parameters.
    %
    % Returns:
    %   points (struct array): Array of building points with position, velocity, rectangle, and eps_r.

    disp('Starting building simulation...');
    tic; 
    nb_buildings = size(conf.buildings.position, 1);
    points = struct('position', [], 'velocity', [], 'rectangle', [], 'eps_r', []);
    
    for i = 1:nb_buildings
        height = conf.buildings.height(i);   % Building height
        length = conf.buildings.length(i);   % Building length

        % Duplicate the building position for all samples (3xN)
        points(i).position = repmat(conf.buildings.position(i, :).', 1, conf.nb_samples);

        % Buildings are static: velocity is zero for all samples (3xN)
        points(i).velocity = zeros(3, conf.nb_samples);

        % Compute rectangle corners for each sample
        x_min = points(i).position(1, :) - length / 2;
        x_max = points(i).position(1, :) + length / 2;
        y_min = points(i).position(2, :);
        y_max = points(i).position(2, :);
        z_min = points(i).position(3, :);
        z_max = points(i).position(3, :) + height;

        rectangles = zeros(3, 4, conf.nb_samples);
        for n = 1:conf.nb_samples
            rectangles(:, :, n) = [ ...
                x_min(n), x_max(n), x_max(n), x_min(n); ...
                y_min(n), y_min(n), y_max(n), y_max(n); ...
                z_min(n), z_min(n), z_max(n), z_max(n) ...
            ];
        end
        points(i).rectangle = rectangles; % 3x4xN array for each building
        points(i).eps_r = conf.buildings.eps_r; % Relative permittivity
    end
    elapsed_time = toc; % Stop timing
    fprintf('\r \t DONE (%.4f seconds)\n', elapsed_time);

end