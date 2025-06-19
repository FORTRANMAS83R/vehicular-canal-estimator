max_jobs=4
job_count=0

for config in src/simulation/config/*.json; do
  config_file=$(basename "$config")
  echo "SIMULATION $config_file"
  ./generate_sample.sh -c "$config_file" &
  ((job_count++))
  if (( job_count >= max_jobs )); then
    wait
    job_count=0
  fi
done
wait