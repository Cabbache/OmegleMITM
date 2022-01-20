# OmegleMITM
Spy on Omegle stranger's video calls from a Linux pc by MITM

## Usage
Assumes you're using Firefox.

1. Run start.sh.
2. Open two Omegle tabs on video chat in a suitable place on the screen but do not give the browser any permissions.
3. Adjust the screen crop to one of the tabs(call it tab A). To adjust it, make the terminal in focus and use WASD,UHJK and NM
4. Press 'B' once finished adjusting.
5. Give permission to tab B for mic 1 and video 1.
6. Adjust the crop for tab B.
7. Press 'B' once finished.
8. Give permissions to tab A for mic 2 and video 2.
9. Whilst doing this you should notice numbers appearing in the terminal. These are the sink-input indexes. When prompted, enter the sink-input index of tab B first and the sink-input index of tab A second. `pacmd list-sink-inputs` can be useful.
10. Paste the following in the browser console of each tab to remove logo.
```console
document.getElementById("videologo").style.opacity = "0";
document.getElementById("othervideo").style.borderRadius = 0;
```
11. Use these commands to control the stream
* `vv 1` - to stream camera to video 1, press any key to stop
* `vv 2` - to stream camera to video 2, press any key to stop
* `pp file.wav 1` - to play sound from file.wav to mic 1
* `pp file.wav 2` - to play sound from file.wav to mic 2

## Dependencies

* ffmpeg
* ffplay
* v4l2loopback-dkms
* pacmd
* pulseaudio

## Some thoughts & info
The script needs much more work for user friendliness and is still in its early stages. However, it was inspired from a need to an alternative to OBS studio. With little or no modification, the script can be used to MITM other video call applications.

### Warnings ###
* Beware it does not clean up background processes.
* You can easily get your IP banned using this.
* The script does not support text based MITM.
