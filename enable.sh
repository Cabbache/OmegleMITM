#!/bin/sh

get_inputs(){
	pacmd list-sink-inputs | grep index | grep -Eo '[0-9]+'
}

get_changes(){
	(echo "$1" && echo "$2") | sort | uniq -c | sed 's/^ *//g' | grep ^1 | cut -d' ' -f2
}

check_changes(){
	while true
	do
		LIST1=$(get_inputs)
		sleep 2
		LIST2=$(get_inputs)
		get_changes "$LIST1" "$LIST2"
	done
}

check_changes &

MAX=$(ls /dev/video* | sort -Vr | head -n1 | sed 's/\/dev\/video//g')
video1=$((MAX + 1))
video2=$((MAX + 2))

#create virtual cameras
sudo modprobe v4l2loopback video_nr=$video1,$video2 card_label="MITM video 1","MITM video 2" exclusive_caps=1

#create virtual audio sinks
pacmd load-module module-remap-sink sink_name=MITM_sink_1
pacmd update-source-proplist MITM_sink_1.monitor device.description=MITM_mic_1

pacmd load-module module-remap-sink sink_name=MITM_sink_2
pacmd update-source-proplist MITM_sink_2.monitor device.description=MITM_mic_2

E1=$(./assist.sh "/dev/video$video1")

X1=$(echo "$E1" | cut -d, -f1)
Y1=$(echo "$E1" | cut -d, -f2)
W1=$(echo "$E1" | cut -d, -f3)
H1=$(echo "$E1" | cut -d, -f4)

sudo ffmpeg -nostats -hide_banner -loglevel error -f x11grab -r 60 -s "$W1"x"$H1" -i :0.0+$X1,$Y1 -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 "/dev/video$video1" &

E2=$(./assist.sh "/dev/video$video2")

X2=$(echo "$E2" | cut -d, -f1)
Y2=$(echo "$E2" | cut -d, -f2)
W2=$(echo "$E2" | cut -d, -f3)
H2=$(echo "$E2" | cut -d, -f4)

sudo ffmpeg -nostats -hide_banner -loglevel error -f x11grab -r 60 -s "$W2"x"$H2" -i :0.0+$X2,$Y2 -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 "/dev/video$video2" &

read -p "sink-input index of tab1: " index1
read -p "sink-input index of tab2: " index2

#make sure to enter the index of correct tab,
#otherwise strangers will hear themselves
pacmd move-sink-input $index2 MITM_sink_1.monitor
pacmd move-sink-input $index1 MITM_sink_2.monitor
