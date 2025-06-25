%
% simulate_buildings - Generates building points for the simulation.
%
% Syntax:
%   points = simulate_buildings(conf)
%
% Description:
%   This function generates the positions, velocities, rectangles, and relative permittivity
%   for a set of buildings in the simulation scenario. Each building is defined by its position,
%   height, length, and relative permittivity. The function outputs a struct array containing
%   the geometry and properties of each building for all simulation samples.
%
% Inputs:
%   conf : struct
%       Configuration structure containing the following fields:
%           - buildings.position : [N x 3] array of building center positions (meters)
%           - buildings.height   : [N x 1] vector of building heights (meters)
%           - buildings.length   : [N x 1] vector of building lengths (meters)
%           - buildings.eps_r    : scalar, relative permittivity of buildings
%           - nb_samples         : integer, number of simulation samples
%
% Outputs:
%   points : struct array
%       Array of structures (1 per building) with fields:
%           - position  : [3 x nb_samples] positions of the building center for each sample
%           - velocity  : [3 x nb_samples] velocities (zero, since buildings are static)
%           - rectangle : [3 x 4 x nb_samples] rectangle corners for each sample
%           - eps_r     : relative permittivity (copied from conf)
%
% Example:
%   conf.buildings.position = [0 0 0; 10 0 0];
%   conf.buildings.height = [5; 8];
%   conf.buildings.length = [10; 12];
%   conf.buildings.eps_r = 4.5;
%   conf.nb_samples = 100;
%   points = simulate_buildings(conf);
%
% Notes:
%   - Each building is assumed static (zero velocity).
%   - Rectangle corners are computed for each sample, but position is constant.
%   - The rectangle is defined in 3D as four corners (x, y, z).
%
% Author: Mikael Franco 
%

function points = simulate_buildings(conf)
    disp('Starting building simulation...');
    tic; 
    nb_buildings = size(conf.buildings.position, 1);
    points = struct('position', [], 'velocity', [], 'rectangle', [], 'eps_r', []);
    
    for i = 1:nb_buildings
        height = conf.buildings.height(i);   % Building height
        length = conf.buildings.length(i);   % Building length

        % Duplicate the building position for all samples (3 x nb_samples)
        points(i).position = repmat(conf.buildings.position(i, :).', 1, conf.nb_samples);

        % Buildings are static: velocity is zero for all samples (3 x nb_samples)
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
        points(i).rectangle = rectangles; % 3 x 4 x nb_samples array for each building
        points(i).eps_r = conf.buildings.eps_r; % Relative permittivity
    end
    elapsed_time = toc; % Stop timing
    fprintf('\r \t DONE (%.4f seconds)\n', elapsed_time);

end