#!/bin/bash

matlab -batch "addpath('src/estimator/neural_networks'); estimate_K_factor('data/all_features.mat', 'train')"
