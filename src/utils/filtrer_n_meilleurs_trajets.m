function [A_out, delay_out, f_d_out, idx_keep] = filtrer_n_meilleurs_trajets(A, delay, f_d, n)
% Garde les n trajets les plus puissants (atténuation la plus faible)
%
% Entrées :
%   A      : atténuation (1xN ou Nx1), en dB
%   delay  : délais (1xN)
%   f_d    : Doppler shifts (1xN)
%   n      : nombre de trajets à garder
%
% Sorties :
%   A_out, delay_out, f_d_out : tableaux filtrés
%   idx_keep : indices globaux conservés

    A = A(:).';  % forcer 1×N
    N = numel(A);

    % Retirer les -Inf
    idx_valid = ~isinf(A);
    A_valid = A(idx_valid);
    delay_valid = delay(idx_valid);
    f_d_valid = f_d(idx_valid);
    idx_valid_all = find(idx_valid);

    % Trier les atténuations (ordre croissant = + puissants d'abord)
    [A_sorted, ord] = sort(A_valid, 'ascend');
    delay_sorted = delay_valid(ord);
    f_d_sorted = f_d_valid(ord);
    idx_sorted = idx_valid_all(ord);

    keep_count = min(n, numel(A_sorted));
    
    A_out     = A_sorted(1:keep_count);
    delay_out = delay_sorted(1:keep_count);
    f_d_out   = f_d_sorted(1:keep_count);
    idx_keep  = idx_sorted(1:keep_count);
end
