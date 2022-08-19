#!/bin/bash

DPI=600

for INPUT in $@; do
	OUTPUT=${INPUT%.*}_crop.pdf

	WIDTH_PTS=$(identify -density ${DPI} -format "%w" ${INPUT})
	HEIGHT_PTS=$(identify -density ${DPI} -format "%h" ${INPUT})

	BON_WIDTH_INCH=$(bc <<< "scale=2; 8/2.54") # inch
	BON_WIDTH_PTS=$(bc <<< "${BON_WIDTH_INCH} * ${DPI}")

	OFFSET_X_PTS=$(bc <<< "${WIDTH_PTS} / 2 - ${BON_WIDTH_PTS} / 2")

	convert -density ${DPI} -crop "${BON_WIDTH_PTS}x${HEIGHT_PTS}+${OFFSET_X_PTS}+0" +repage -compress JPEG ${INPUT} ${OUTPUT}
done
