#!/bin/bash
##
 # Incremental backups with Btrfs snapshots
 #
 # This script does incremental backups of Btrfs subvolumes
 # across filesystem boundaries as proposed in the Btrfs wiki:
 #  https://btrfs.wiki.kernel.org/index.php/Incremental_Backup
 #
 # It uses the 'btrfs send' and 'btrfs receive' commands.
 # Its not intended for simple snapshots in a single filesystem enviroment.
 #
 # @copyright   2013 Steffen Vogel
 # @license     http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author      Steffen Vogel <info@steffenvogel.de>
 # @link        http://www.steffenvogel.de
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

# TODO: delete old snapshots in destination fs
# TODO: print statistics of send | receive pipe (speed & size)

function usage {
	echo "Usage: $(basename $0) SOURCE [DEST]"
	echo
	echo "   SOURCE  a path to the subvolume to backup"
	echo "   DEST    an optional path to the backup destination"
	echo "             only required for initialization"
	exit 1
}

set -e

if [ $# -lt 1 ]; then
	echo -e "missing source"
	echo
	usage
fi

SRC=$(readlink -f "$1")

if [ -h "$SRC/.backup/destination" ]; then
	DEST=$(readlink -f "$SRC/.backup/destination")
elif [ $# -ne 2 ] ; then
	echo -e "missing destination"
	echo
	usage
else
	DEST=$(readlink -f $2)

	mkdir -p "$SRC/.backup/"
	mkdir -p "$DEST"

	ln -sf "$DEST" "$SRC/.backup/destination"
	ln -sf "$SRC" "$DEST/source"
fi

# name for the new snapshot
SNAPSHOT=$(date +%F_%H-%M-%S)
LATEST="$SRC/.backup/$SNAPSHOT"

# snapshot the current state
btrfs subvolume snapshot -r "$SRC" "$LATEST"

# send changes
if [ -h "$DEST/latest-source" ]; then
	PREVIOUS=$(readlink -f "$DEST/latest-source")
	btrfs send -p "$PREVIOUS" "$LATEST" | btrfs receive "$DEST"
else
	btrfs send "$LATEST" | btrfs receive "$DEST"
fi

# delete old snapshot in source fs
if [ -n "$PREVIOUS" ]; then
	btrfs subvolume delete "$PREVIOUS"
fi

# update links to last backup
ln -rsfT "$DEST/$SNAPSHOT" "$DEST/latest"
ln -sfT "$LATEST" "$DEST/latest-source"

