function points = normal_vector(points, Tx)
    % NORMAL_VECTOR - Orients normal vectors for points.
    %
    % Parameters:
    %   points (struct array): Array of points with 'position' and 'velocity'.
    %   Tx (array): Transmitter position.
    %
    % Returns:
    %   points (struct array): Points with oriented normal vectors.

    N = numel(points);

    % Extract positions and velocities into 3xN matrices
    positions = [points.position];
    velocities = [points.velocity];

    % Work only in the XY plane (2xN)
    Vxy = velocities(1:2, :);
    toTx = Tx(1:2) - positions(1:2, :);

    % Two orthogonal vectors in the plane (±90° rotation)
    n1 = [-Vxy(2, :); Vxy(1, :)];
    n2 = [Vxy(2, :); -Vxy(1, :)];

    % Dot products for the two orientations
    dot1 = sum(n1 .* toTx, 1);
    dot2 = sum(n2 .* toTx, 1);

    % Choose the correct vector based on the dot product sign
    use_n1 = dot1 > dot2;

    % Prepare the array of oriented normal vectors
    Nxy = zeros(2, N);
    Nxy(:, use_n1) = n1(:, use_n1);
    Nxy(:, ~use_n1) = n2(:, ~use_n1);

    Nxy = Nxy ./ vecnorm(Nxy); % Normalize

    % Add a z-component of 0
    N3D = [Nxy; zeros(1, N)];

    % Assign the normal vectors to the structure
    for i = 1:N
        points(i).n = N3D(:, i);
    end
end

