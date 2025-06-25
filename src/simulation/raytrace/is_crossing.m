function is_crossing = is_crossing(A, B, P1, P2, P3, P4)
    % IS_CROSSING - Checks if a segment intersects a rectangle in 3D space.
    %
    % Syntax:
    %   is_crossing = is_crossing(A, B, P1, P2, P3, P4)
    %
    % Description:
    %   This function determines whether the segment [A,B] intersects the rectangle defined
    %   by the four vertices P1, P2, P3, P4 in 3D space. The intersection is computed by
    %   finding the intersection point of the segment with the plane of the rectangle and
    %   then checking if this point lies inside the rectangle.
    %
    % Inputs:
    %   A, B   : [1 x 3] arrays
    %       Endpoints of the segment.
    %   P1, P2, P3, P4 : [1 x 3] arrays
    %       Vertices of the rectangle (ordered).
    %
    % Outputs:
    %   is_crossing : logical
    %       True if the segment intersects the rectangle, false otherwise.
    %
    % Notes:
    %   - The rectangle is assumed to be planar and defined by its four corners.
    %   - The function uses a helper function isPointInRectangle to check if a point is inside the rectangle.
    %
    % Author: Mikael Franco
    %

    % Calculate the normal vector of the rectangle's plane
    v1 = P2 - P1;
    v2 = P4 - P1;
    normal = cross(v1, v2);
    normal = normal / norm(normal);

    % Direction of the segment
    dir = B - A;
    denom = dot(normal, dir);

    if abs(denom) < 1e-6
        is_crossing = false;
        return;
    end

    % Intersection parameter
    t = dot(normal, (P1 - A)) / denom;

    if t < 0 || t > 1
        is_crossing = false;
        return;
    end

    % Intersection point
    I = A + t * dir;

    % Check if the point is inside the rectangle
    is_crossing = isPointInRectangle(I, P1, P2, P4);
end

function is_inside = isPointInRectangle(P, P1, P2, P4)
    % isPointInRectangle - Checks if a point is inside a rectangle.
    %
    % Parameters:
    %   P (array): Point to check.
    %   P1, P2, P4 (array): Vertices of the rectangle.
    %
    % Returns:
    %   is_inside (logical): True if the point is inside the rectangle.

    u = P2 - P1; % Horizontal side
    v = P4 - P1; % Vertical side
    w = P - P1;

    u_norm2 = dot(u, u);
    v_norm2 = dot(v, v);

    alpha = dot(w, u) / u_norm2;
    beta = dot(w, v) / v_norm2;

    eps = 1e-4;
    is_inside = (alpha > eps) && (alpha < 1 - eps) && (beta > eps) && (beta < 1 - eps);
end
