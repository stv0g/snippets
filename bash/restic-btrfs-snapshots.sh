#!/bin/bash
##
 # Convert BTRFS snapshots to Restic Snapshots
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

PARENT=""

HOST=$1

AFTER=$(date -d"$2" +%s)

for SNAP in $(ls -1); do

	D=$(echo $SNAP | cut -d_ -f1)
	T=$(echo $SNAP | cut -d_ -f2 | tr - :)
	W=$(date -d "$D $T" +%u)

	if [ -z "$D"  -o -z "$T" -o -z "$W" ]; then
		echo "Failed to parse: $SNAP"
		break
	fi

	if [ -n "$PARENT" ]; then
		RESTIC_OPTS="--parent $PARENT"
	else
		RESTIC_OPTS=""
	fi

	if [ "$W" != "7" ]; then continue; fi

	echo $SNAP
	continue

	UNIX=$(date -d"$D $T" +%s)
	if (( $UNIX < $AFTER )); then continue; fi
	pushd $SNAP
	restic backup $RESTIC_OPTS --tag old_btrfs_snapshot --host $HOST --time "$D $T" --ignore-inode .
	popd

	PARENT=$(restic snapshots --tag old_btrfs_snapshot --host $HOST --last --json | jq -r .[0].id)
done
