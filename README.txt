# Build FFmpeg with NVIDIA Video Codec

## Introduction

This repo. contains the Dockerfile to setup a development environment for building FFmpeg with NVIDIA Video Codec (NVENC) support.

Prequisites:
- A CUDA-enabled NVIDIA GPU
- NVIDIA GPU driver and CUDA toolkit installed on the host machine
- NVIDIA Container Toolkit installed on the host machine
- Docker installed on the host machine

This repo. has the following submodules (the corresponding versions are labeled):
- FFmpeg: n7.1.1
- nv-codec-headers: n12.2.72.0
You can check this by `git submodule status`, after cloning this repo.

## Usage

### Build the docker image (can be skipped if you use VS Code devcontainer)

``` cmd @host
# cd to THIS directory
docker build -t ffmpeg-nv-dev .
```

### Launch the container (can be skipped if you use VS Code devcontainer)

``` cmd @host
# cd to ffmpeg-nv-dev directory (parent directory of this README.txt)
docker run -it --runtime=nvidia --gpus all --mount type=bind,src=$(pwd),dst=/home/ubuntu/workspace/ffmpeg-nv-dev ffmpeg-nv-dev /bin/bash

### Get the source code of FFmpeg and nv-codec-headers

``` cmd @container
cd /home/ubuntu/workspace/ffmpeg-nv-dev
git submodule update --init --recursive
```

### Build the FFmpeg with NVENC support

Install nv-codec-headers:
``` cmd @container
cd /home/ubuntu/workspace/ffmpeg-nv-dev/nv-codec-headers
sudo make install
```
Build FFmpeg:
``` cmd @container
cd /home/ubuntu/workspace/ffmpeg-nv-dev/FFmpeg
./configure \
	--enable-nonfree \
	--enable-cuda-nvcc \
	--enable-libnpp \
	--enable-libpulse \
	--extra-cflags=-I/usr/local/cuda/include \
	--extra-ldflags=-L/usr/local/cuda/lib64 \
	--disable-static \
	--enable-shared
make -j 8
sudo make install
```

### Test with example video

The test video data is NOT included in this repo.
Please prepare your own video data.

``` cmd @container
ffmpeg -y -vsync 0 -hwaccel cuda -hwaccel_output_format cuda -i SampleVideo_1280x720_1mb.mp4 -vf scale_npp=1920:1080 -c:a copy -c:v h264_nvenc -b:v 5M output1.mp4 -vf scale_npp=640:360 -c:a copy -c:v h264_nvenc -b:v 8M output2.mp4
```
The above command will generate two output videos with different resolutions by scaling the input video.

## Tips

The dependent submodules point to forked repos.
In order to checkout a specific tag, one can add the original repo as another remote, and then checkout the desited tag, and push it to the forked repo. using `git push <remote> tag <tag-name>`.

## References

1. [Using FFmpeg with NVIDIA GPU Hardware Acceleration](https://docs.nvidia.com/video-technologies/video-codec-sdk/12.2/ffmpeg-with-nvidia-gpu/index.html)
2. [Compile FFmpeg for Ubuntu, Debian, or Mint](https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu)
3. [FFmpeg Docker image project](https://github.com/jrottenberg/ffmpeg)
