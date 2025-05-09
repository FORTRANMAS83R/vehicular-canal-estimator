function traffic_params = set_traffic_params(v_min, v_max, a_min, a_max, d_cible, dt)
    % SET_TRAFFIC_PARAMS - Configures traffic parameters for the simulation.
    %
    % Parameters:
    %   v_min, v_max (float): Minimum and maximum velocities (m/s).
    %   a_min, a_max (float): Minimum and maximum accelerations (m/s^2).
    %   d_cible (float): Target distance between vehicles (m).
    %   dt (float): Time step for the simulation (s).
    %
    % Returns:
    %   traffic_params (struct): Struct containing traffic configuration parameters.

    % Configure velocity parameters
    traffic_params.velocity.minimum = v_min; 
    traffic_params.velocity.maximum = v_max;

    % Configure acceleration parameters
    traffic_params.acceleration.minimum = a_min;
    traffic_params.acceleration.maximum = a_max;

    % Configure target distance and time step
    traffic_params.distance.target = d_cible;
    traffic_params.dt = dt; 
end