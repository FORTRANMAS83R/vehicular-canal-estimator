#!/bin/bash

# Valeur par défaut
config="config_new.json"

# Lecture des options
while getopts "c:" opt; do
  case $opt in
    c) config="$OPTARG" ;;
    *) echo "Usage: $0 [-c config_file.json]"; exit 1 ;;
  esac
done

for snr in {1..20}; do
  echo "SIMULATION SNR ${snr} dB"
  ./launchSimulation.sh "$config" -snr $snr -num_paths 15
done