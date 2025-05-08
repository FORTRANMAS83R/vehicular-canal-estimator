function [p1, v1, a1, p2, v2, a2 ] = traffic_manager(traffic_params, spawn_range, vehicule_step, nb_vehicules, nb_samples, dt)
    [p1, v1, a1] = lane_manager(traffic_params, spawn_range{1}, vehicule_step(1), nb_vehicules(1), nb_samples);
    [p2, v2, a2] = lane_manager(traffic_params, spawn_range{2}, vehicule_step(2), nb_vehicules(2), nb_samples);
end 