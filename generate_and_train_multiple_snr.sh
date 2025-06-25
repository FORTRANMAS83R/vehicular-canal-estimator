#!/bin/bash
# generate_and_train_multiple_snr.sh - Automates simulation, feature extraction, and K-factor estimator training for multiple SNR values.
#
# Usage:
#   ./generate_and_train_multiple_snr.sh [-c config.json] [-skip_gen]
#
# Description:
#   This script automates the process of:
#     1. Running the vehicular channel simulation for SNR values from 0 to 20 dB (unless -skip_gen is set).
#     2. Extracting features from the generated .h5 files using MATLAB.
#     3. Training a neural network K-factor estimator for each feature set using MATLAB.
#   Results (RMSE, R2, R2_lin) are saved to a text file.
#
# Options:
#   -c config.json   Specify the simulation configuration file (default: crossing.json)
#   -skip_gen        Skip the simulation step and only run feature extraction and training
#
# Notes:
#   - Requires launchSimulation.sh, MATLAB, and the appropriate MATLAB scripts/functions in the path.
#   - Output .h5 files are saved in data/samples/dataset_1/
#   - Feature .mat files are saved in data/features/dataset_1/
#   - Training results are saved in data/train_K_estimator_results.txt
#
# Author: Mikael Franco
#

#!/bin/bash

# Default values
config="crossing.json"
max_jobs=4
job_count=0
skip_gen=0

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c)
      config="$2"
      shift 2
      ;;
    -skip_gen)
      skip_gen=1
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Generation loop (skip if -skip_gen is set)
if [[ $skip_gen -eq 0 ]]; then
  for snr in {0..20}; do
    echo "SIMULATION SNR ${snr} dB"
    ./launchSimulation.sh "$config" -snr $snr -num_paths 15 -output "data/samples/dataset_1/snr_${snr}_dB.h5" &
    ((job_count++))
    if (( job_count >= max_jobs )); then
      wait
      job_count=0
    fi
  done
  wait
fi

input_folder="data/samples"
output_folder="data/features"

mkdir -p "$output_folder"

for h5file in "$input_folder"/*.h5; do
    name=$(basename "$h5file" .h5)
    output_file="$output_folder/${name}_features.mat"
    echo "Processing $h5file -> $output_file"
    matlab -batch "addpath('src/utils'); build_features('-input', '$h5file', '-output', '$output_file')"
done

output_file="train_K_estimator_results.txt"
> "$output_file"

files=(data/features/*.mat)
num_files=${#files[@]}

echo "Processing $num_files files..."

for file in  data/features/*.mat; do
    echo "Processing $file"
    # Call train_K_estimator, which should print MSE, R2, R2_lin on a single line
    matlab -batch "addpath('src/estimator/neural_networks'); [rmse, R2, R2_lin] = estimate_K_factor('$file', 'train'); disp([rmse, R2, R2_lin])"