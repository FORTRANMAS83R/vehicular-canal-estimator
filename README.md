# Vehicular Canal Estimator

This repository provides a complete simulation and estimation pipeline for vehicular wireless channels, including:

- Scenario generation
- Channel modeling (multipath and Rician fading)
- Signal transmission/reception
- Feature extraction
- K-factor estimation using statistical and neural network approaches

---

##  Quick Start

You can run the provided `setup.sh` script to automatically create all required folders and prepare the environment before running any simulation or training scripts.

---

##  Folder Structure

Before running any scripts, make sure the following folders exist:

> Note: The `data/` folder is included in `.gitignore` and will not be tracked by git.

---

##  How to Use the Scripts

###  Prerequisites
- MATLAB (with Signal Processing and Neural Network Toolboxes)
- Bash (for shell scripts)
- HDF5 support in MATLAB

---

###  Main Scripts

#### A. Simulation
Run a simulation for a given scenario:

- Main entry point: `simulation.m`
- Batch example:
```bash
./launchSimulation.sh config.json -snr 10 -num_paths 15 -output snr_10_dB.h5
```

#### B. Batch Simulation, Feature Extraction, and Training
Automate the full pipeline:
```bash
./generate_and_train_multiple_snr.sh 
```
- Runs simulations for SNRs from 0 to 20 dB
- Extracts features from generated `.h5` files
- Trains a neural network estimator for each SNR and saves results

#### C. Feature Extraction
Extract features from a `.h5` file using:
```matlab
build_features.m
```

#### D. K-factor Estimation
Train or evaluate a neural network:
```matlab
estimate_K_factor.m
```

#### E. Visualization and Evaluation
Plot RMSE and R² vs SNR:
```matlab
plot_results.m
```

---

##  Simulation and Estimation Logic

### A. Scenario and Channel Simulation

#### Configuration
All simulation parameters are set in a JSON file (see `crossing.json` for an example). Includes:

- Number and properties of vehicles/buildings
- Antenna/emitter parameters (modulation, carrier frequency, etc.)
- Sample count, SNR, and more

#### Scenario Generation
- Vehicles and buildings are generated according to configuration
- Each object has position, velocity, and physical properties (e.g. permittivity)

#### Ray Tracing and Path Modeling
- For each sample, compute all LOS and multipath paths
- Use geometric filtering for obstacle detection
- Compute delay, attenuation, Doppler shift, Rice K-factor

#### Channel Simulation
- Modeled as sum of multipath rays (delay, Doppler, Rician/Rayleigh fading)
- Add noise to the transmitted waveform

#### Data Storage
- For each sample, save:
  - `/sample_i_real`
  - `/sample_i_imag`
  - `/sample_i_K` (true K-factor)
  
  Stored in `.h5` files

---

### B. Feature Extraction and K-factor Estimation

#### Feature Extraction
- Extracted from received signal
- Stored in `.mat` file
- Handled by `build_features.m`

#### K-factor Estimation
Two methods:

1. **Statistical**: moment-based estimators
2. **Neural Network**: feedforward NN on extracted features

- Script: `estimate_K_factor.m`

#### Evaluation
- Compute RMSE and R² vs SNR
- Save plots, metrics, and trained models in `data/`

---

##  References
- See `README.md` and script comments for more details
- Example configuration and data provided in respective folders

---

**Author**: Mikael Franco  

---

