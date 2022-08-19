#!/bin/bash
##
 # Opens all LUKS volumes
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

# Set IFS to a newline:
IFS="
"

for VOLUME in $(ls -1 /dev/vg*/*-luks); do
	if ! cryptsetup isLuks ${VOLUME}; then
		echo "${VOLUME} is not a luks device"
		continue
	fi

	if [ -b /dev/disk/by-id/dm-uuid-*$(cryptsetup luksUUID ${VOLUME} | tr -d -)* ]; then
		echo "${VOLUME} is opened"
	else
		NAME=$(basename -s '-luks' ${VOLUME})

		cryptsetup luksOpen --allow-discards ${VOLUME} ${NAME}

#		systemd-ask-password --id="zfs:$dataset" \
#		"Enter passphrase for '$dataset':" | \
# 		zfs load-key "$dataset"
	fi
done
