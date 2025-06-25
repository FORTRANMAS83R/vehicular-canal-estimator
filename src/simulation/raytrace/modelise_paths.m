% filepath: c:\code\liu\vehicular-canal-estimator\src\simulation\raytrace\modelise_paths.m
%
% modelise_paths - Models the propagation paths between a transmitter and receiver.
%
% Syntax:
%   [delay, A, f_d, K] = modelise_paths(Tx, Rx, points, f_c, num_paths)
%
% Description:
%   This function computes the physical parameters of propagation paths (LOS and multipaths)
%   between a transmitter and receiver in a simulated environment. It filters out obstructed paths,
%   computes delays, attenuations, Doppler shifts, and the Rice K-factor for each path.
%
% Inputs:
%   Tx        : struct
%       Transmitter structure with fields:
%           - position : [3 x 1] position vector (meters)
%           - velocity : [3 x 1] velocity vector (m/s)
%   Rx        : struct
%       Receiver structure with fields:
%           - position : [3 x 1] position vector (meters)
%           - velocity : [3 x 1] velocity vector (m/s)
%   points    : struct array
%       Array of objects/obstacles with fields:
%           - position : [3 x N] positions of reflection points
%           - velocity : [3 x N] velocities of reflection points
%           - n        : [3 x N] normal vectors at reflection points
%           - eps_r    : relative permittivity
%   f_c       : double
%       Carrier frequency (Hz)
%   num_paths : integer
%       Number of best multipaths to keep (besides LOS)
%
% Outputs:
%   delay : array
%       Path delays (seconds) for each path (including LOS)
%   A     : array
%       Path attenuations (dB) for each path (including LOS)
%   f_d   : array
%       Doppler shifts (Hz) for each path (including LOS)
%   K     : array
%       Rice K-factor for each path (including LOS)
%
% Notes:
%   - The function first filters out points that are blocked by obstacles.
%   - The LOS (Line-Of-Sight) path is always included.
%   - Reflection coefficients are computed using Fresnel equations.
%   - The K-factor is computed as the ratio of LOS power to total NLOS power.
%   - Attenuation includes random fading (alpha) for multipaths.
%
% Author: Mikael Franco
%

function [delay, A, f_d, K] = modelise_paths(Tx, Rx, points, f_c, num_paths)
    addpath('src/utils');

    c = 3e8; % Speed of light in m/s
    f = f_c; % Frequency in Hz
    lambda = c / f; % Wavelength in meters
    tic; % Start timing the raytracing

    % Filter points that intersect with obstacles
    points = filtrerPoints(Tx.position, Rx.position, points);

    % LOS path calculations
    delay_los = vecnorm(Rx.position - Tx.position) / c;
    A_el_los = -(20 * log10(vecnorm(Rx.position - Tx.position)) + 20 * log10(f) + 20 * log10(4 * pi / c));
    f_d_los = 1 / lambda * dot((Rx.velocity - Tx.velocity), (Rx.position - Tx.position)/norm(Rx.position - Tx.position));

    if isempty(points)
        delay = [delay_los]; 
        A = [A_el_los];
        f_d = [f_d_los];
        K = [10000]; % No multipaths, K factor is very high (pure LOS)
        return;
    end

    % Extract positions and velocities
    positions = [points.position];
    velocities = [points.velocity];

    % Calculate the delay for each path
    distance = vecnorm(positions - Tx.position) + vecnorm(Rx.position - positions);
    delay = distance / c;

    % Calculate attenuation (free-space + reflection)
    A_el = 20 * log10(distance) + 20 * log10(f) + 20 * log10(4 * pi / c);
    points = normal_vector(points, Tx.position);

    % Calculate angles and reflection coefficients
    r = positions - Tx.position;
    norms = vecnorm(r);
    nonzero = norms > 0;
    r(:,nonzero) = r(:,nonzero) ./ norms(nonzero);

    n = [points.n];
    angles = acosd(abs(sum(n .* r, 1)));
    cell_angles = num2cell(angles);
    [points.theta] = deal(cell_angles{:});

    theta = [points.theta];
    eps_r = [points.eps_r];
    sig_te = (cosd(theta) - sqrt(eps_r - sind(theta).^2)) ./ (cosd(theta) + sqrt(eps_r - sind(theta).^2));
    sig_tm = (eps_r .* cosd(theta) - sqrt(eps_r - sind(theta).^2)) ./ (eps_r .* cosd(theta) + sqrt(eps_r - sind(theta).^2));
    sig = 1/2 * (abs(sig_te).^2 + abs(sig_tm).^2);
    A = A_el - 10 * log10(sig);

    % Add random fading for multipaths
    alpha = normrnd(0.25, 0.05, [1, numel(A)]); 
    if any(alpha < 0)
        alpha(alpha < 0) = 0.1; 
    end
    alpha_db = 10 * log10(alpha);
    A = -A ;
    A = A + alpha_db;

    % Calculate Doppler shift for each path
    q = Rx.position - positions;
    norms = vecnorm(q);
    nonzero = norms > 0;
    q(:,nonzero) = q(:,nonzero) ./ norms(nonzero);

    f_d = 1 / lambda * (dot((velocities - Tx.velocity), r )+ dot((Rx.velocity - velocities), q));

    % Keep only the N best multipaths
    [A, delay, f_d, idx] = filtrer_n_meilleurs_trajets(A, delay, f_d, num_paths);

    % Add LOS path to the lists
    A = [A,  A_el_los];
    f_d = [f_d, f_d_los];
    delay = [delay, delay_los]; % Include LOS delay

    % Compute Rice K-factor
    K = zeros(1, numel(A)-1);
    P  = 10.^(A / 10);     
    P_los  = P(end);     
    P_nlos = sum(P) - P_los; 
    K_los = P_los / P_nlos;
    K = [K, K_los]; % Include LOS K factor
end