# Record the start time of the simulation
start=$(date +%s)

# Get all arguments
ARGS=("$@")
JSON_PATH=${ARGS[0]}
# Build the argument string for MATLAB (enclose each argument in single quotes and separate by commas)
MATLAB_ARGS="'src/simulation/config/$JSON_PATH'"
for ((i=1; i<${#ARGS[@]}; i++)); do
    MATLAB_ARGS+=", '${ARGS[$i]}'"
done

echo "Starting the simulation - Configuration path: $JSON_PATH"
echo "Passing arguments to MATLAB: $MATLAB_ARGS"

# Launch MATLAB in batch mode and call the simulation function with all arguments
matlab -batch "addpath(genpath('src/simulation')); simulation($MATLAB_ARGS)"

# Record the end time of the simulation
end=$(date +%s)

# Calculate and display the runtime
runtime=$((end - start))
echo "Simulation completed in $runtime seconds"