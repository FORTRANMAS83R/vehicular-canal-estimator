% filtrerPoints - Filters points that do not intersect with a segment.
%
% Syntax:
%   points_filtered = filtrerPoints(A, B, points)
%
% Description:
%   This function filters a set of points (typically representing objects or obstacles)
%   and returns only those whose rectangles do not intersect with the segment defined by points A and B.
%   The intersection test is performed using the is_crossing function.
%
% Inputs:
%   A, B   : [1 x 3] arrays
%       Endpoints of the segment in 3D space.
%   points : struct array
%       Array of points, each with a 'rectangle' field (3 x 4 matrix).
%
% Outputs:
%   points_filtered : struct array
%       Subset of input points whose rectangles do not intersect the segment [A,B].
%
% Notes:
%   - The function assumes that each point's 'rectangle' field is a 3x4 matrix representing the corners.
%   - The function is_crossing(A, B, P1, P2, P3, P4) must be available in the path.
%
% Author: Mikael Franco
%

function points_filtered = filtrerPoints(A, B, points)
    points_filtered = [];
    for i = 1:numel(points)
        R = points(i).rectangle;
        % Test intersection between segment [A,B] and rectangle corners
        if ~is_crossing(A, B, R(:,1), R(:,2), R(:,3), R(:,4))
            points_filtered = [points_filtered, points(i)];
        end
    end
end
