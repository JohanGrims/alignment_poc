# Alignment POC

A proof-of-concept application for evaluating contextual sliding-window sentence alignment. Built with **Flutter** (for the frontend) and **Rust** + **ONNX Runtime** (for tokenization, contextual embedding, and alignment logic).

## Features
- **Sliding Window Alignment:** A robust two-stage algorithm to align translated documents at the paragraph and sentence levels, effectively handling omissions and restructuring.
- **Local AI Embeddings:** Uses the ONNX Runtime and tokenizers via Rust to compute high-performance embeddings completely locally without needing external APIs.
- **Cross-Platform Desktop:** Supports Linux and Windows natively.

## Architecture
- **Flutter UI (`lib/`)**: Provides the frontend interface for running test cases, triggering alignments, and visualizing the evaluation output.
- **Rust Backend (`rust/`)**: Implements the sliding window alignment engine with contextual token-level embeddings.
- **Flutter Rust Bridge**: Enables seamless, zero-copy interop between the Dart UI and the heavy Rust computation layer.

## Build Requirements

To build the application yourself, ensure you have the following installed:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.22.x)
- [Rust Toolchain](https://rustup.rs/) (cargo, rustc)
- CMake, Clang, and Ninja (for compiling native components)

## Building the App

**For Linux:**
```bash
flutter build linux
```

**For Windows:**
```powershell
flutter build windows
```
*(Windows release builds can also be packaged using the included `windows/installer.iss` Inno Setup script).*

## Automated Builds
This repository includes a GitHub Actions CI/CD pipeline that automatically builds and bundles artifacts (a Linux bundle and a Windows Setup Installer) whenever changes are pushed to the `main` branch.
