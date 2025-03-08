#/bin/bash

ffmpeg -i $1 -c copy -an output_file.mp4
