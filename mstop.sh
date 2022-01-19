#!/bin/sh
kill $(pgrep enable)
sudo kill $(pgrep ffmpeg)
sudo modprobe --remove v4l2loopback
pacmd unload-module module-remap-sink
