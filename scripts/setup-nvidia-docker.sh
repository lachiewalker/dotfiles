#!/usr/bin/env bash
# Configure Docker to use the NVIDIA Container Runtime.
# Run once after nvidia-container-toolkit is installed via apt.
# Required for `docker run --gpus all` to work.
set -euo pipefail

if ! command -v nvidia-ctk &>/dev/null; then
    echo "Error: nvidia-container-toolkit not installed. Run scripts/install-packages.sh first." >&2
    exit 1
fi

echo "==> Configuring Docker NVIDIA runtime"
sudo nvidia-ctk runtime configure --runtime=docker

echo "==> Restarting Docker"
sudo systemctl restart docker

echo "==> Done. Test with: docker run --rm --gpus all ubuntu nvidia-smi"
