#!/bin/bash
##
 # Find images taken with little time diff (panoramas)
 #
 # @copyright	2012 Steffen Vogel
 # @license	http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author	Steffen Vogel <info@steffenvogel.de>
 # @link	http://www.steffenvogel.de/
 ##
##
 # This script is free software: you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation, either version 3 of the License, or
 # any later version.
 #
 # This script is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 # GNU General Public License for more details.
 #
 # You should have received a copy of the GNU General Public License
 # along with this script. If not, see <http://www.gnu.org/licenses/>.
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
