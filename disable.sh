#!/bin/sh
sudo modprobe --remove v4l2loopback
pacmd unload-module module-remap-sink
