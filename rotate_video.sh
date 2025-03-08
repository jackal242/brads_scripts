#/bin/bash

ffmpeg -i 10000000_397317002751798_3791671601302524288_n.mp4 -c copy -metadata:s:v:0 rotate=90 output.mp4
