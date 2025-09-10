#!/bin/bash

# @file: ffmpeg-nv-dev/build.sh
# @brief: Build ffmpeg with NVENC support from source
# @usage: ./build.sh

set -euo pipefail

# Set the environment variable for linking the CUDA library
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/lib"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[INFO] Script is running from: $SCRIPT_DIR"

# Check if running as root (required for make install)
if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] This script must be run as root (for make install)" 
   exit 1
fi

# Step 1: Get the source code of FFmpeg and nv-codec-headers
echo "=== [INFO] Getting source code of FFmpeg and nv-codec-headers ==="
# Call `git submodule update --init --recursive` if necessary

# Step 2: Install nv-codec-headers
echo "=== [INFO] Installing nv-codec-headers ==="
cd "$SCRIPT_DIR/nv-codec-headers"
make install

# Step 3: Build FFmpeg with NVENC support
echo "=== [INFO] Building FFmpeg with NVENC support ==="
INSTALL_DIR="/opt/ffmpeg"
mkdir -p "$SCRIPT_DIR/FFmpeg/build"
cd "$SCRIPT_DIR/FFmpeg/build"

# Configure FFmpeg with NVENC support
../configure \
	--enable-nonfree \
	--enable-cuda-nvcc \
	--enable-libnpp \
	--enable-libpulse \
	--extra-cflags=-I/usr/local/cuda/include \
	--extra-ldflags=-L/usr/local/cuda/lib64 \
	--disable-static \
	--enable-shared

# Build FFmpeg
echo "=== [INFO] Compiling FFmpeg (using 16 parallel jobs) ==="
make -j 16

# Install FFmpeg
echo "=== [INFO] Installing FFmpeg ==="
make install

# Update library cache
echo "=== [INFO] Updating library cache ==="
ldconfig

echo "=== [INFO] Build completed successfully! ==="
echo "	FFmpeg with NVENC support has been built and installed."
echo "	"
echo "	You can test the installation with:"
echo "	ffmpeg -version"
echo "	"
echo "	To test with the sample video, run:"
echo "	cd $SCRIPT_DIR"
echo "	ffmpeg -y -vsync 0 -hwaccel cuda -hwaccel_output_format cuda -i test/SampleVideo_1280x720_2mb.mp4 -vf scale_npp=1920:1080 -c:a copy -c:v h264_nvenc -b:v 5M output1.mp4 -vf scale_npp=640:360 -c:a copy -c:v h264_nvenc -b:v 8M output2.mp4"
