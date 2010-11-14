#!/bin/sh
ffmpeg -i "$1" -f mp4 -vcodec mpeg4 -maxrate 1000 -b 700 -qmin 3 -qmax 5 -bufsize 4096 -g 300 -acodec aac -ar 44100 -ab 192 -s 320x240 -aspect 4:3 $2
