#!/bin/bash

get_inputs(){
	pacmd list-sink-inputs | grep index | grep -Eo '[0-9]+'
}

get_changes(){
	(echo "$1" && echo "$2") | sort | uniq -c | sed 's/^ *//g' | grep ^1 | cut -d' ' -f2
}

exitdn(){
	echo "Could not find dependency '$1'"
	exit
}

check_dep(){
	command -v "$1" > /dev/null || exitdn "$1"
}

check_deps(){
	check_dep "ffmpeg"
	check_dep "pacmd"
	check_dep "ffplay"
	check_dep "play"
	#you might also need to apt install v4l2loopback-dkms
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

setup(){
	check_deps

	check_changes &
	CHPID=$!

	#create virtual cameras in /dev/videoX
	MAX=$(ls /dev/video* | sort -Vr | head -n1 | sed 's/\/dev\/video//g')
	video1=$((MAX + 1))
	video2=$((MAX + 2))
	sudo modprobe v4l2loopback video_nr=$video1,$video2 card_label="MITM video 1","MITM video 2" exclusive_caps=1

	#create virtual audio sinks
	pacmd load-module module-remap-sink sink_name=MITM_sink_1
	pacmd update-source-proplist MITM_sink_1.monitor device.description=MITM_mic_1
	pacmd load-module module-remap-sink sink_name=MITM_sink_2
	pacmd update-source-proplist MITM_sink_2.monitor device.description=MITM_mic_2

	E1=$(./crop_assist.sh "/dev/video$video1")

	X1=$(echo "$E1" | cut -d, -f1)
	Y1=$(echo "$E1" | cut -d, -f2)
	W1=$(echo "$E1" | cut -d, -f3)
	H1=$(echo "$E1" | cut -d, -f4)

	sudo ffmpeg -nostats -hide_banner -loglevel error -f x11grab -r 60 -s "$W1"x"$H1" -i :0.0+$X1,$Y1 -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 "/dev/video$video1" &
	PID1=$!

	E2=$(./crop_assist.sh "/dev/video$video2")

	X2=$(echo "$E2" | cut -d, -f1)
	Y2=$(echo "$E2" | cut -d, -f2)
	W2=$(echo "$E2" | cut -d, -f3)
	H2=$(echo "$E2" | cut -d, -f4)

	sudo ffmpeg -nostats -hide_banner -loglevel error -f x11grab -r 60 -s "$W2"x"$H2" -i :0.0+$X2,$Y2 -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 "/dev/video$video2" &
	PID2=$!

	read -p "sink-input index of tab1: " index1
	read -p "sink-input index of tab2: " index2

	pacmd move-sink-input $index2 MITM_sink_1
	pacmd move-sink-input $index1 MITM_sink_2
	kill $CHPID
}

vv(){
	if [ $1 == 1 ]; then
		PID=$PID1
		WIDTH=$W1
		HEIGHT=$H1
	elif [ $1 == 2 ]; then
		PID=$PID2
		WIDTH=$W2
		HEIGHT=$H2
	else
		echo "Invalid number, neither 1 or 2"
		continue
	fi
	VIDEO="/dev/video$((MAX+$1))"

	sudo kill -STOP $(pgrep -P "$PID") #pause MITM stream
	sudo ffmpeg -nostats -hide_banner -loglevel error -f v4l2 -i /dev/video0 -vf "format=yuv420p,scale=$WIDTH:$HEIGHT" -f v4l2 "$VIDEO" &
	echo "streaming /dev/video0 to $VIDEO"
	read -rsn1 #pause until key enter
	sudo kill -9 $(pgrep -P $!)
	sudo kill -CONT $(pgrep -P "$PID") #continue MITM stream
}

pp(){
	play $1 > /dev/null 2>&1 & (sleep 0.1 && pacmd move-sink-input $(pacmd list-sink-inputs | grep -B15 "sox" | head -n1 | cut -d' ' -f6) "MITM_sink_$2")
}

setup

#vv 1 - to stream camera to video 1, press any key to stop
#vv 2 - to stream camera to video 2, press any key to stop
#pp file.wav 1 - to play sound from file.wav to mic 1
#pp file.wav 2 - to play sound from file.wav to mic 2

while true
do
	read -p '>> ' ent
	$ent
done
