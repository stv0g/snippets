#!/bin/bash

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
