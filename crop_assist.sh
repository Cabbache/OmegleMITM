#!/bin/bash

#This script is intended to assist a user or another script in
#finding the exact x,y position and width,height of a rectangle
#on the screen so that ffmpeg can be used to crop it and stream
#it to /dev/videoX

if [[ $# -ne 1 ]]
then
	echo "Usage: $0 /dev/videoX"
	echo "
WASD - move
UHJK - change dimensions
M and N - increment/decrement step size
B - exit
	"
	exit
fi

readkey(){
	read -rsn1 key
	echo $key | tr '[:upper:]' '[:lower:]'
}

readkeynum(){
	key=$(readkey)
	printf "%d\n" \'$key
}

a2d(){
	printf "%d\n" \'$1
}

f_left(){((X-=STEP));}
f_right(){((X+=STEP));}
f_up(){((Y-=STEP));}
f_down(){((Y+=STEP));}

f_wup(){((W+=STEP));}
f_wdown(){((W-=STEP));}
f_hup(){((H+=STEP));}
f_hdown(){((H-=STEP));}

f_sup(){((STEP++));}
f_sdown(){((STEP--));}

STEP=50
X=0
Y=0

W=640
H=480

MP=()
MP[$(a2d a)]=f_left
MP[$(a2d d)]=f_right
MP[$(a2d w)]=f_up
MP[$(a2d s)]=f_down

MP[$(a2d h)]=f_wdown
MP[$(a2d k)]=f_wup
MP[$(a2d u)]=f_hup
MP[$(a2d j)]=f_hdown

MP[$(a2d m)]=f_sup
MP[$(a2d n)]=f_sdown

MP[$(a2d b)]=break

adjust(){
	#show what is being cropped
	ffplay -nostats -hide_banner -loglevel error "$1" &

	while true
	do
		#stream to /dev/videoX
		sudo ffmpeg -nostats -hide_banner -loglevel error -f x11grab -r 60 -s "$W"x"$H" -i :0.0+$X,$Y -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 -vf scale=640:480 "$1" &

		#wait for key press
		keynum=$(readkeynum)

		#kill previous ffmpeg
		for pid in $(jobs -p | grep -v $(jobs -p %1)) 
		do
			cpid=$(pgrep -P $pid)
			[ -z "$cpid" ] && continue #if cpid is empty, continue
			sudo kill $cpid
		done

		#execute instruction depending on key pressed (could be break from loop)
		${MP[keynum]}

		#print info about current state to stderr
		>&2 echo "TOP LEFT: $X,$Y | WIDTH,HEIGHT: $W,$H | STEP: $STEP"
	done
	kill $(pgrep ffplay)
}

adjust "$1"
echo "$X,$Y,$W,$H"
