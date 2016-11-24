#!/bin/bash

SRC=${1:-${DROPBOX}/Apps/tapiriik}
DEST=${2:-${DROPBOX}/Apps/cartodb}

SPORTS=""

# Convert all TXC into GPX files
for FILE in ${SRC}/*.tcx
do
	BASE=$(basename "${FILE// /_}" .tcx)
	INPUT="${FILE}"
	OUTPUT="${BASE}.gpx"

	SPORT="${BASE##*_}"
	SPORT="${SPORT%% *}"

	SPORTS="$SPORTS $SPORT"

	echo "Converting $INPUT to $OUTPUT of Sport $SPORT"

	mkdir -p "${DEST}/${SPORT}"

	${BABEL} -t -r -w -i gtrnctr -f "${INPUT}" -x track,speed -o gpx -F "${DEST}/${SPORT}/${OUTPUT}"
done

SPORTS=$(echo $SPORTS | tr ' ' '\n' | sort -u | tr '\n' ' ')

# Merge all activities per sport
for SPORT in ${SPORTS}
do
	FILES=""

	for FILE in ${DEST}/${SPORT}/*.gpx; do
		FILES="$FILES -f $FILE"
	done

	echo "Merging into $SPORT.gpx"

	${BABEL} -t -r -w -i gpx ${FILES} -o gpx -F ${DEST}/${SPORT}.gpx
done