function traffic_params=  set_traffic_params(v_min, v_max, a_min, a_max, d_cible, dt)
    traffic_params.velocity.minimum = v_min; 
    traffic_params.velocity.maximum = v_max;
    traffic_params.acceleration.minimum = a_min;
    traffic_params.acceleration.maximum = a_max;
    traffic_params.distance.target = d_cible;
    traffic_params.dt = dt; 
end 