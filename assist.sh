#!/bin/bash
#640x480

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

killffmpeg(){
	for pid in `pgrep ffmpeg`
	do
	 sudo kill -9 $pid
	done
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
X=2575
Y=426

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

MP[$(a2d l)]=break

function adjust(){
	ffplay /dev/video6 &
	while true
	do
		sudo ffmpeg -nostats -hide_banner -loglevel error -f x11grab -r 60 -s "$W"x"$H" -i :0.0+$X,$Y -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 -vf scale=640:480 "/dev/video6" &
		keynum=$(readkeynum)
		${MP[keynum]}
		killffmpeg
		echo "TOP LEFT -->> $X,$Y"
		echo "WIDTH,HEIGHT -->> $W,$H"
		echo "STEP -->> $STEP"
	done
	kill $(pgrep ffplay)
	killffmpeg
}

adjust
