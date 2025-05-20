function results = keep_top_n(results, n)
%KEEP_TOPN  Keep, for each sample, the n largest values of A.
%
%   results = KEEP_TOPN(results, n)
%
%   • results : struct array (1×Nsamples) with fields A, B, C, etc.
%   • n       : number of indices to keep (positive integer).
%
%   Rules:
%     1. Positions where A == -Inf are always removed.
%     2. If more than n values remain, only the n largest are kept.
%     3. If ≤ n values remain, all are kept.
%
%   Other fields are truncated with the same indices.
    
    if nargin ~= 2 || ~isscalar(n) || n <= 0
        error('Invalid argument n: provide an integer > 0.');
    end

    for k = 1:numel(results)
        A = results(k).A(:);            % column vector
        valid = ~isinf(A);              % exclude -Inf
        if ~any(valid)                  % all are -Inf → clear fields
            results(k) = clear_fields(results(k));
            continue
        end

        % Sort valid values of A in descending order
        [~, ord]  = sort(A(valid), 'descend');
        keepCount = min(n, numel(ord));
        keptLocal = ord(1:keepCount);   % indices among the "valid"

        % Convert to global indices
        globalIdx = find(valid);
        keepIdx   = globalIdx(keptLocal);

        % Filter all fields of same length as A, and also 3 x lenA matrices
        fn = fieldnames(results(k));
        lenA = numel(A);
        for f = 1:numel(fn)
            v = results(k).(fn{f});
            if numel(v) == lenA
                results(k).(fn{f}) = v(keepIdx);
            elseif ismatrix(v) && size(v,2) == lenA && size(v,1) == 3
                results(k).(fn{f}) = v(:, keepIdx);
            end
        end
    end
end


