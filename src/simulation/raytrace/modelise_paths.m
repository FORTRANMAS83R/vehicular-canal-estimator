function [delay, A, f_d] = modelise_paths(Tx, Rx, points, f_c)
    % MODELISE_PATHS - Models the paths between a transmitter and receiver.
    %
    % Parameters:
    %   Tx (struct): Transmitter with fields 'position'.
    %   Rx (struct): Receiver with fields 'position'.
    %   points (struct array): Array of points with fields 'position' and 'velocity'.
    %
    % Returns:
    %   delay (array): Path delays for each point.
    %   A (array): Attenuation for each path.
    %   f_d (array): Doppler shift for each path.

    c = 3e8; % Speed of light in m/s
    f = f_c; % Frequency in Hz
    lambda = c / f; % Wavelength in meters
    tic; % Start timing the raytracing

    % Filter points that intersect with obstacles
    points = filtrerPoints(Tx.position, Rx.position, points);
    if isempty(points)
        return; % Exit if no valid points remain
    end

    % Extract positions and velocities
    positions = [points.position];
    velocities = [points.velocity];

    % Calculate the delay for each path
    distance = vecnorm(positions - Tx.position) + vecnorm(Rx.position - positions);
    delay = distance / c;

    % Calculate attenuation
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
    sig(isnan(sig)) = 0; 
    A = A_el + 20 * log10(sig);

    % Calculate Doppler shift
    q = Rx.position - positions;
    norms = vecnorm(q);
    nonzero = norms > 0;
    q(:,nonzero) = q(:,nonzero) ./ norms(nonzero);
    
    f_d = 1 / lambda * ((velocities - Tx.velocity) .* r + (Rx.velocity - velocities) .* q);
    
end