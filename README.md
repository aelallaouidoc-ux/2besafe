# 2besafe
# BeSafe – AI-based Worker Safety Monitoring System

## Overview

BeSafe is a smart worker safety monitoring system designed to detect physiological stress and health risks in real time.  
The system combines **wearable physiological signals**, **machine learning**, and a **mobile monitoring application** to help supervisors monitor worker health and prevent accidents.

This project was developed as part of a **Huawei competition submission**.

The system integrates:

- Physiological signal monitoring
- Machine learning–based risk detection
- Real-time mobile dashboard
- Predictive safety analytics


# System Architecture

The project contains two main components:

### 1. AI Stress Detection Model
A machine learning model trained on the **WESAD dataset** to detect stress conditions using physiological signals.

### 2. Mobile Monitoring Application
A **Flutter mobile application** that visualizes worker vitals and integrates the AI model for risk prediction.


# Dataset

## WESAD Dataset

The **WESAD (Wearable Stress and Affect Detection)** dataset is a publicly available dataset used for stress detection research.

It contains physiological signals recorded from wearable sensors during different emotional states.

### Sensors included

- ECG (Electrocardiogram)
- EDA (Electrodermal Activity)
- BVP (Blood Volume Pulse)
- Temperature
- Accelerometer

### Classes

- Baseline
- Stress
- Amusement
- Meditation

In this project we focus on:

- **Baseline (0)**
- **Stress (1)**

Dataset source:

https://archive.ics.uci.edu/dataset/465/wesad+wearable+stress+and+affect+detection


# Machine Learning Model

## Algorithm

The project uses a **Random Forest Classifier** for stress detection.


# Feature Engineering

Physiological signals are segmented into **time windows**.

From each window, statistical features are extracted:

Examples:

- Mean
- Standard deviation
- Minimum
- Maximum
- Signal variance
- Signal energy

These features are then used as input to the Random Forest classifier.

# Model Training

The training pipeline consists of:

1. Load WESAD dataset
2. Extract physiological signals
3. Segment signals into windows
4. Extract statistical features
5. Train Random Forest classifier
6. Evaluate performance
7. Export trained model

The trained model is exported as:
random_forest_wesad.onnx


This format allows integration into the mobile application.


# Installation

## 1 Install Python dependencies


pip install -r requirements.txt




The model outputs:

- Stress probability
- Risk classification


# Mobile Application

The mobile application is built with **Flutter**.

The app includes:

### Supervisor Dashboard
- Overview of all workers
- Risk alerts
- Health monitoring

### Worker Monitoring
- Heart rate
- SpO₂
- Temperature
- Blood pressure

### AI Risk Detection
The ONNX model is embedded inside the application to provide **local AI inference**.

This allows:

- real-time prediction
- offline operation
- low latency

# Technologies Used

### AI / Data Science

- Python
- Scikit-learn
- NumPy
- Pandas
- ONNX
- ONNX Runtime

### Mobile Application

- Flutter
- Dart

### Data Visualization

- Flutter charts
- Custom trend visualization


# Results

The Random Forest model achieved competitive performance for stress detection on WESAD physiological data.

Metrics evaluated include:

- Accuracy
- Precision
- Recall
- F1 Score

These results demonstrate the feasibility of using wearable physiological data for worker safety monitoring.

# Open Source

This project is provided as an **open-source implementation** including:

- training code
- inference code
- dataset samples
- trained model
- documentation
