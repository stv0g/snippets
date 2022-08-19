#!/bin/bash
##
 # Startup wrapper to workaround a bug in EAGLE
 #
 # Cadsoft EAGLE fails to open filename including whitespaces on linux systems.
 # This script creates a temporary symlink and redirects the supplied filename to
 # the temporary one.
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

ARGS=$@
FILE=$1
SUF=${FILE##*.}

if [ "$SUF" = "brd" -o "$SUF" = "sch" -o "$SUF" = "epf" ]; then
	FILE=$(readlink -f "$FILE")
	ARGS=/tmp/eagle.$SUF

	ln -sf "$FILE" "$ARGS"

	if [ "$SUF" = "brd" ]; then
		ln -sf "${FILE%.*}.sch" /tmp/eagle.sch
	elif [ "$SUF" = "sch" ]; then
		ln -sf "${FILE%.*}.brd" /tmp/eagle.brd
	fi
fi

LD_LIBRARY_PATH=/opt/eagle/lib/ exec /opt/eagle/6.1.0/bin/eagle $ARGS
#LD_LIBRARY_PATH=/opt/libpng14/lib /opt/eagle-6.1.0/bin/eagle $ARGS

rm -f /tmp/eagle.*
