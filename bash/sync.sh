#!/bin/sh
##
 # rsync backup
 #
 # for automated syncronisation of my home directory
 #
 # @copyright	2012 Steffen Vogel
 # @license	http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author	Steffen Vogel <info@steffenvogel.de>
 # @link	http://www.steffenvogel.de
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

# Hostname or IP address of remote box
HOST=sea

# Maximum file size. Larger files will be exluded
MAX_SIZE=500

# Nice factor for rsync
NICENESS=10

# Interval in minutes to reschedule this script via at
# Set to 0 to disable
INTERVAL=180

# Choose own queue for sync jobs
# Uppercase letters will at let behave like batch
QUEUE=S


# Exclude files bigger than MAX_SIZE
find $HOME -type f -size +$(($MAX_SIZE*1024))k > $HOME/rsync.large.exclude


# Start logfile
touch $HOME/rsync.log
echo started: $(date) | tee $HOME/rsync.log

# Notify
if [ -x /usr/bin/notify-send ]; then
	notify-send \
		-h int:transient:1 \
		-a "rsync" \
		-c "transfer" \
		-i "/usr/share/icons/gnome/256x256/actions/appointment.png" \
		-u low -t 1000 \
		"Syncronization started" "excluding:\n$(cat ~/*.exclude)"
fi


/usr/bin/time \
	-a -o $HOME/rsync.log \
	-f "secs elapsed: %e" \
nice \
	-n ${NICENESS} \
rsync \
	--human-readable \
	--exclude-from=$HOME/rsync.exclude \
	--exclude-from=$HOME/rsync.large.exclude \
	--archive \
	--xattrs \
	--delete \
	--executability \
	--links \
	--compress \
	--out-format=%f \
	--stats \
	$HOME/ $HOST:$HOME/backup/ \
2>&1 | tee -a $HOME/rsync.log

echo finished: $(date) | tee -a $HOME/rsync.log

# Resync logfile
scp $HOME/rsync.log $HOST:$HOME/backup/

# Notify
if [ -x /usr/bin/notify-send ]; then
	notify-send \
		-h int:transient:1 \
		-a "rsync" \
		-c "transfer.complete" \
		-i "/usr/share/icons/gnome/256x256/actions/appointment.png" \
		-u low -t 2000 \
		"Syncronisation completed" "$(tail -n16 ~/rsync.log)"
fi

# Prune queue
JOBS=$(atq -q ${QUEUE} | cut -f 1 | xargs)
if [ -n "${JOBS}" ]; then
	atrm ${JOBS}
fi

# Queue next run
if [ ${INTERVAL} -ne 0 ]; then
	echo "bash $0" | at -q ${QUEUE} "now + ${INTERVAL} minutes"
fi
