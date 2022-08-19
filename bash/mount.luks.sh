#!/bin/bash
##
 # [u]mount(8) helper for luks encrypted disks
 #
 # Both mount and umount offer the ability to handover the mounting
 # process to a helper script. This is usefull when mounting/unmounting
 # luks encrypted disks. This helper combines the following steps for mounting
 # a disk:
 #
 #  1. cryptsetup luksOpen DEV UUID
 #  2. mount -o helper=luks /dev/mapper/UUID DIR
 #
 # respectivly for unmounting
 #
 #  1. umount -i DEV
 #  2. cryptsetup luksClose UUID
 #
 # INSTALL:
 #     place this script in /sbin/mount.luks and make it executable.
 #
 # USAGE:
 #     mount -t luks /dev/sda1 /home
 #
 # or via /etc/fstab:
 #     /dev/sda1  /home  luks  defaults  0  0
 # followed by:
 #     mount /home
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

if [ "$(basename $0)" == "mount.luks" ]; then
	DEV=$1
	DIR=$2

	shift 2
	OPTS=$@

	UUID=$(cryptsetup luksUUID $DEV)
	if [ $? -ne 0 ]; then
		echo -e "$DEV is not a LUKS device"
		exit 1
	fi

	cryptsetup luksOpen $DEV $UUID
	mount $OPTS -o helper=luks /dev/mapper/$UUID $DIR

	# NOTE: The mount option '-o helper=luks' is essentially required
	# because the encrypted filesystem is not of type "luks".
	# This option tells umount to use this helper script,
	# instead of using the normal unmounting procedure and
	# leaving the dm-crypt volume unclosed and therefore unproteced!

elif [ "$(basename $0)" == "umount.luks" ]; then
	DEV=$(mount | grep $1 | cut -f 1 -d " ")
	UUID=$(basename $DEV)

	shift
	OPTS=$@

	umount -i $OPTS $DEV
	# NOTE: The umount option '-i' is essentially required. It skips this
	# helper script which would cause otherwise an endless self recursion

	cryptsetup luksClose $UUID
fi
