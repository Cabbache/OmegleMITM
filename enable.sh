#!/bin/sh

MAX=$(ls /dev/video* | sort -Vr | head -n1 | sed 's/\/dev\/video//g')
video1=$((MAX + 1))
video2=$((MAX + 2))

sudo modprobe v4l2loopback video_nr=$video1,$video2 card_label="MITM video 1","MITM video 2" exclusive_caps=1

#echo "Select screen that will have "
#xrandr | grep connected | grep -v disconnected

read -p "X1: " X1
read -p "Y1: " Y1
read -p "W1: " W1
read -p "H1: " H1

read -p "X2: " X2
read -p "Y2: " Y2
read -p "W2: " W2
read -p "H2: " H2

#640x480
sudo ffmpeg -f x11grab -r 60 -s $W1x$H1 -i :0.0+$X1,$Y1 -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 "/dev/video$video1"
sudo ffmpeg -f x11grab -r 60 -s $W2x$H2 -i :0.0+$X2,$Y2 -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 "/dev/video$video2"

#create virtual sinks
pacmd load-module module-remap-sink sink_name=MITM_sink_1
pacmd update-sink-proplist MITM_sink_1 device.description=MITM_sink_1

pacmd load-module module-remap-sink sink_name=MITM_sink_2
pacmd update-sink-proplist MITM_sink_2 device.description=MITM_sink_2

#now you must setup omegle in browser to create sink-inputs
#also you must allow omegle to use the sinks created (MITM 1 & 2)
#once omegle has access to them it will create the sink-input which
#we need to find their index

read -p "sink-input index of tab1" index1
read -p "sink-input index of tab2" index2

#make sure to enter the index of correct tab,
#otherwise strangers will hear themselves
pacmd move-sink-input $index2 MITM_sink_1
pacmd move-sink-input $index1 MITM_sink_2
