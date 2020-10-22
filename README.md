# Cell-Image-Analysis-Pipeline
This repository contains a neural network trained on yeast images, which is capable of detecting cells and their vacuoles. Scripts for training the neural network and analyse the output are also available.

Image processing, parallel processing and deep learning toolboxes are required. Scripts were designed for MATLAB 2020a. They do work on 2019B, but shuffling during training does not function.

### Usage
1. Run "training.m" to train the supplied neural network on your data.

2. Run "analysis1.m" to detect yeast cells and their vacuoles.

3. Run "analysis2.m" to get cell and vacuole volume data.

### Cite this work
[https://doi.org/10.1101/2020.10.22.350355 ](https://www.biorxiv.org/content/10.1101/2020.10.22.350355v1)
