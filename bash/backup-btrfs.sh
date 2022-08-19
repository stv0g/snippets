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
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

# TODO: delete old snapshots in source and destination fs

set -e

function usage {
	echo "Usage: $(basename $0) SOURCE [DEST]"
	echo
	echo "   SOURCE  a path to the subvolume to backup"
	echo "   DEST    an optional path to the backup destination"
	echo "             only required for initialization"
	exit 1
}

if [ $# -lt 1 ]; then
	echo -e "missing source"
	echo
	usage
fi

SRC=$(readlink -e "$1")
if [ $SRC == "/" ]; then
	SRC=""
fi

if [ -h "$SRC/.backup/destination" ]; then
	DEST=$(readlink -e "$SRC/.backup/destination")
elif [ $# -ne 2 ] ; then
	echo -e "missing destination"
	echo
	usage
else
	DEST=$(readlink -e $2)
fi

# create directories if not existing
mkdir -p "$SRC/.backup/"
mkdir -p "$DEST/"

# create symbolic links if not existing
ln -snf "$DEST/" "$SRC/.backup/destination"
ln -snf "$SRC/" "$DEST/source"

# name for the new snapshot
SNAPSHOT=$(date +%F_%H-%M-%S)
LATEST="$SRC/.backup/$SNAPSHOT"

# snapshot the current state
btrfs subvolume snapshot -r "$SRC/" "$LATEST/"

# send changes
if [ -h "$DEST/latest-source" ]; then
	PREVIOUS=$(readlink -e "$DEST/latest-source")
	btrfs send -p "$PREVIOUS/" "$LATEST/" | pv | btrfs receive "$DEST/"
else
	btrfs send "$LATEST/" | pv | btrfs receive "$DEST/"
fi

# delete old snapshot in source fs
if [ -n "$PREVIOUS" ]; then
	btrfs subvolume delete "$PREVIOUS/"
fi

# update links to last backup
ln -rsfT "$DEST/$SNAPSHOT" "$DEST/latest"
ln -sfT "$LATEST" "$DEST/latest-source"
