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
    ./launchSimulation.sh "$config" -snr $snr -num_paths 15 -output "data/samples/multiple_snr/snr_${snr}_dB.h5" &
    ((job_count++))
    if (( job_count >= max_jobs )); then
      wait
      job_count=0
    fi
  done
  wait
fi
#!/bin/bash

input_folder="data/samples/multiple_snr"
output_folder="data/features_multiple_snr"

mkdir -p "$output_folder"

# for h5file in "$input_folder"/*.h5; do
#     name=$(basename "$h5file" .h5)
#     output_file="$output_folder/${name}_features.mat"
#     echo "Processing $h5file -> $output_file"
#     matlab -batch "addpath('src/utils'); build_features('-input', '$h5file', '-output', '$output_file')"
# done

output_file="train_K_estimator_results.txt"
> "$output_file"

files=(data/features_multiple_snr/*.mat)
num_files=${#files[@]}

echo "Processing $num_files files..."

for ((i=0; i<num_files; i++)); do
    file="${files[$i]}"
    echo "Processing $file"
    # Call train_K_estimator, which should print MSE, R2, R2_lin on a single line
    matlab -batch "addpath('src/estimator/neural_networks'); [rmse, R2, R2_lin] = estimate_K_factor('$file'); disp([rmse, R2, R2_lin])" >> "data/$output_file"
done 