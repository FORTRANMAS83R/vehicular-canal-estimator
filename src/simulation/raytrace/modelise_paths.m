function [delay, A, f_d, K] = modelise_paths(Tx, Rx, points, f_c, num_paths)
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
    addpath('src/utils');

    c = 3e8; % Speed of light in m/s
    f = f_c; % Frequency in Hz
    lambda = c / f; % Wavelength in meters
    tic; % Start timing the raytracing

    % Filter points that intersect with obstacles
    points = filtrerPoints(Tx.position, Rx.position, points);
    delay_los = vecnorm(Rx.position - Tx.position) / c;
    A_el_los = -(20 * log10(vecnorm(Rx.position - Tx.position)) + 20 * log10(f) + 20 * log10(4 * pi / c));
    f_d_los = 1 / lambda * dot((Rx.velocity - Tx.velocity), (Rx.position - Tx.position)/norm(Rx.position - Tx.position));


    if isempty(points)
        delay = [delay_los]; 
        A = [A_el_los];
        f_d =   [f_d_los];
        K = [10000]; % No paths, K factor is zero
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
    A = A_el - 10 * log10(sig);
    alpha = normrnd(0.25, 0.05, [1, numel(A)]); 
    if any(alpha < 0)
        alpha(alpha < 0) = 0.1; 
    end
    alpha_db = 10 * log10(alpha);
    A = -A ;
    A = A + alpha_db;
    % Calculate Doppler shift
    q = Rx.position - positions;
    norms = vecnorm(q);
    nonzero = norms > 0;
    q(:,nonzero) = q(:,nonzero) ./ norms(nonzero);
    
    f_d = 1 / lambda * (dot((velocities - Tx.velocity), r )+ dot((Rx.velocity - velocities), q));

     
    [A, delay, f_d, idx] = filtrer_n_meilleurs_trajets(A, delay, f_d, num_paths);
    %Implement an normal distributed alpha that lowers the gain of multipaths 
    A = [A,  A_el_los];
    f_d = [f_d, f_d_los];
    delay = [delay, delay_los]; % Include LOS delay


    

    
    
    
     % Include LOS Doppler shift
    K = zeros(1, numel(A)-1);
    P  = 10.^(A / 10);     
    P_los  = P(end);     
    P_nlos = sum(P) - P_los; 
    
    K_los = P_los / P_nlos;
    %K_los = 10 * log10(P_los / P_nlos);
    K = [K, K_los]; % Include LOS K factor

    
    
end