function points = normal_vector(points, Tx)
    % NORMAL_VECTOR - Sets normal vectors as the y-projection of (Point -> Tx).
    %
    % Parameters:
    %   points (struct array): Array of points with 'position'.
    %   Tx (array): Transmitter position (3x1).
    %
    % Returns:
    %   points (struct array): Points with normal vectors as y-projection.

    N = numel(points);
    for i = 1:N
        y_diff = Tx(2) - points(i).position(2);
        % If you want a unit vector (normalize if not zero)
        if y_diff ~= 0
            n = [0; sign(y_diff); 0];
        else
            n = [0; 0; 0];
        end
        points(i).n = n;
    end
end

