
function simulate_traffic()
    fprintf('Starting traffic simulation...');
    tic; 
    traffic_params = set_traffic_params(0, 30, -2.5, 2.5, 10, 1); % Exemple d'appel de la fonction
    %lane_manager(traffic_params, [0, 100], 5, 10, 13); % Exemple d'appel de la fonction
    [p1, v1, a1, p2, a2, v2] = traffic_manager(traffic_params, {[0, 100, 0]; [100, 0, 10]}, [5, 5], [10, 10], 13, 1); % Exemple d'appel de la fonction
    elapsed_time = toc;
    fprintf('\r DONE (%.4f seconds)\n', elapsed_time);
end 