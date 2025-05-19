function points_filtered = filtrerPoints(A, B, points)
    % FILTRERPOINTS - Filters points that do not intersect with a segment.
    %
    % Parameters:
    %   A, B (array): Endpoints of the segment.
    %   points (struct array): Array of points with 'rectangle' field.
    %
    % Returns:
    %   points_filtered (struct array): Points that do not intersect the segment.

    points_filtered = [];
    for i = 1:numel(points)
        R = points(i).rectangle;

        if ~is_crossing(A, B, R(:,1), R(:,2), R(:,3), R(:,4))
            points_filtered = [points_filtered, points(i)];
        end
    end
end
