function simulation(json_file)
    % SIMULATION - Main function to run the vehicular canal simulation
    %
    % Parameters:
    %   json_file (string): Path to the JSON configuration file.
    %
    % This function reads the configuration file, calculates the coherence
    % time based on the maximum Doppler shift, and runs the traffic simulation.
    % The results are saved in an HDF5 file.

    % Add the vehicles directory to the MATLAB path
    addpath('src/simulation/vehicles');

    % Check if the JSON configuration file exists
    if ~isfile(json_file)
        error('No such JSON file found: %s', json_file);
    end

    % Read and decode the JSON configuration file
    raw = fileread(json_file);
    conf = jsondecode(raw);

    % Calculate the coherence time based on the maximum Doppler shift
    % T_c = (0.423 * c) / (v_max * f), where:
    %   c = speed of light (3 * 10^8 m/s)
    %   v_max = maximum velocity (m/s)
    %   f = emitter frequency (Hz)
    T_c = (0.423 * 3e8) / (conf.traffic.maximum_velocity * conf.emmiter.f); % in seconds
    fprintf('Simulation duration: %.4f milliseconds\n', T_c * 1000);

    % Run the traffic simulation
    [p1, v1, a1, p2, a2, v2] = simulate_traffic( ...
        conf.traffic.minimum_velocity, ...
        conf.traffic.maximum_velocity, ...
        conf.traffic.minimum_acceleration, ...
        conf.traffic.maximum_acceleration, ...
        conf.traffic.minimum_distance, ...
        T_c, ...
        conf.traffic.lane_1.spawn_range, ...
        conf.traffic.lane_2.spawn_range, ...
        conf.traffic.lane_1.vehicule_step, ...
        conf.traffic.lane_2.vehicule_step, ...
        conf.traffic.lane_1.nb_vehicles, ...
        conf.traffic.lane_2.nb_vehicles, ...
        conf.nb_samples ...
    );

    % Save the simulation results to an HDF5 file
    output_file = 'data\positions_lane1.h5';
    if isfile(output_file)
        delete(output_file); % Delete the file if it already exists
    end
    h5create(output_file, '/p1', size(p1)); % Create the dataset
    h5write(output_file, '/p1', p1);        % Write the data
end


