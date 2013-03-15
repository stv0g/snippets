#!/bin/bash
##
 # Startup wrapper to workaround a bug in EAGLE
 #
 # Cadsoft EAGLE fails to open filename including whitespaces on linux systems.
 # This script creates a temporary symlink and redirects the supplied filename to
 # the temporary one.
 #
 # @copyright	2013 Steffen Vogel
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

ARGS=$@
FILE=$1
SUF=${FILE##*.}

if [ "$SUF" = "brd" -o "$SUF" = "sch" -o "$SUF" = "epf" ]
then
	FILE=$(readlink -f "$FILE")
	ARGS=/tmp/eagle.$SUF
	ln -sf "$FILE" "$ARGS"
fi

LD_LIBRARY_PATH=/opt/libpng14/lib /opt/eagle-6.1.0/bin/eagle $ARGS

rm -f /tmp/eagle.*
