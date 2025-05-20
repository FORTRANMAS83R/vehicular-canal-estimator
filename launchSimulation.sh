# Record the start time of the simulation
start=$(date +%s)

# Get the JSON configuration file path from the first argument
JSON_PATH=$1
echo "Starting the simulation - Configuration path: $JSON_PATH"

# Launch MATLAB in batch mode and call the simulation function
matlab -batch "addpath(genpath('src/simulation')); simulation('src/simulation/config/$JSON_PATH', '$2')"

# Record the end time of the simulation
end=$(date +%s)

# Calculate and display the runtime
runtime=$((end - start))
echo "Simulation completed in $runtime seconds"