# Build FFmpeg with NVIDIA Video Codec

## Introduction

This repo. contains the Dockerfile to setup a development environment for building FFmpeg with NVIDIA Video Codec (NVENC) support.

Prequisites:
- A CUDA-enabled NVIDIA GPU
- NVIDIA GPU driver and CUDA toolkit installed on the host machine
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed on the host machine
- Docker installed on the host machine

This repo. has the following submodules (the corresponding versions are labeled):
- FFmpeg: n7.1.1
- nv-codec-headers: n12.2.72.0
You can check this by `git submodule status`, after cloning this repo.

## Usage

### Build the docker image (can be skipped if you use VS Code devcontainer)

``` cmd @host
cd .devcontainer
docker build --network=host -f Dockerfile.ubuntu-build-ffmpeg -t pd-imagine:ubuntu-build-ffmpeg .
```

### Launch the container (can be skipped if you use VS Code devcontainer)

``` cmd @host
# cd to ffmpeg-nv-dev directory (parent directory of this README.txt)
docker run -it --runtime=nvidia --gpus all --mount type=bind,src=$(pwd),dst=/wksp/ffmpeg-nv-dev pd-imagine:ubuntu-build-ffmpeg /bin/bash
```
Note, you will be logging in as root user in the container.

### Get the source code of FFmpeg and nv-codec-headers

``` cmd @container
cd /wksp/ffmpeg-nv-dev
git submodule update --init --recursive
```

### Build the FFmpeg with NVENC support

Install nv-codec-headers:
``` cmd @container
cd /wksp/ffmpeg-nv-dev/nv-codec-headers
make install
```
Build FFmpeg:
``` cmd @container
cd /wksp/ffmpeg-nv-dev/FFmpeg
./configure \
	--enable-nonfree \
	--enable-cuda-nvcc \
	--enable-libnpp \
	--enable-libpulse \
	--extra-cflags=-I/usr/local/cuda/include \
	--extra-ldflags=-L/usr/local/cuda/lib64 \
	--disable-static \
	--enable-shared
make -j 16
make install
```

### Test with example video

A test video clip from [5] is included in this repo.
It is obtained by `wget https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_2MB.mp4 -O SampleVideo_1280x720_2mb.mp4`.

Run the following command to transcode the input video to two output videos with different resolutions:
``` cmd @container
ffmpeg -y -vsync 0 -hwaccel cuda -hwaccel_output_format cuda -i SampleVideo_1280x720_2mb.mp4 -vf scale_npp=1920:1080 -c:a copy -c:v h264_nvenc -b:v 5M output1.mp4 -vf scale_npp=640:360 -c:a copy -c:v h264_nvenc -b:v 8M output2.mp4
```

## Tips

The dependent submodules point to forked repos.
In order to checkout a specific tag, one can add the original repo as another remote, and then checkout the desited tag, and push it to the forked repo. using `git push <remote> tag <tag-name>`.

To install NVIDIA Container Toolkit:
```
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
```

To configure docker:
```
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## References

1. [Using FFmpeg with NVIDIA GPU Hardware Acceleration](https://docs.nvidia.com/video-technologies/video-codec-sdk/12.2/ffmpeg-with-nvidia-gpu/index.html)
2. [Compile FFmpeg for Ubuntu, Debian, or Mint](https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu)
3. [FFmpeg Docker image project](https://github.com/jrottenberg/ffmpeg)
4. https://durian.blender.org/
5. [Sintel - Blender Open Movie Project](https://durian.blender.org/)
