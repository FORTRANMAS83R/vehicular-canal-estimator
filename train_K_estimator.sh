#!/bin/bash

# for file in data/samples/*.h5; do
#   echo "Traitement de $file"
#   matlab -batch "addpath('src/estimator/neural_networks'); estimate_K_factor('$file', 'train')"
# done

matlab -batch "addpath('src/estimator/neural_networks'); estimate_K_factor('data/all_features.mat', 'train')"
