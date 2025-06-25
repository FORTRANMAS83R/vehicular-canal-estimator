% filepath: c:\code\liu\vehicular-canal-estimator\src\simulation\raytrace\normal_vector.m
%
% normal_vector - Sets normal vectors as the y-projection of (Point -> Tx).
%
% Syntax:
%   points = normal_vector(points, Tx)
%
% Description:
%   This function assigns a normal vector to each point in the input struct array.
%   The normal is set as the y-axis projection (unit vector in +y or -y direction)
%   from the point to the transmitter position Tx. If the y-difference is zero,
%   the normal is set to [0; 0; 0].
%
% Inputs:
%   points : struct array
%       Array of points with a 'position' field (3x1 vector).
%   Tx     : [3 x 1] array
%       Transmitter position.
%
% Outputs:
%   points : struct array
%       Same as input, but with an added field 'n' (normal vector, 3x1).
%
% Notes:
%   - The normal is [0; 1; 0] if Tx is above the point in y, [0; -1; 0] if below.
%   - If Tx and the point have the same y-coordinate, the normal is [0; 0; 0].
%
% Author: Mikael Franco
%

function points = normal_vector(points, Tx)
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