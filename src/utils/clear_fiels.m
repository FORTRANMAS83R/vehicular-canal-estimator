function s = clear_fields(s)
% Met à zéro les champs vectoriels (même longueur que A)
    fn   = fieldnames(s);
    lenA = numel(s.A);
    for f = 1:numel(fn)
        v = s.(fn{f});
        if numel(v) == lenA
            s.(fn{f}) = [];
        end
    end
end