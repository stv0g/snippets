#!/bin/bash
##
 # Find images taken with little time diff (panoramas)
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

MIN_DIFF=5
LAST_TS=0

mkdir panorama

for i in *.JPG; do
	TS=`stat -c %Y $i`

	let DIFF=$TS-$LAST_TS

	if [ "$DIFF" -lt "$MIN_DIFF" ]; then
		echo $i
		cp $i panorama/$i
	fi

	LAST_TS=$TS
done
