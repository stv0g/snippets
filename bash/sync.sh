#!/bin/bash
##
 # rsync backup
 #
 # for automated syncronisation of my home directory
 #
 # @copyright 2021, Steffen Vogel
 # @license	http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author	Steffen Vogel <post@steffenvogel.de>
 # @link	https://www.steffenvogel.de
 ##

# Hostname or IP address of remote box
HOST=lian
HOST_REMOTE=lux

# Maximum file size. Larger files will be exluded
MAX_SIZE=1000
MAX_SIZE_REMOTE=500

# Nice factor for rsync
NICENESS=10

# Interval in minutes to reschedule this script via at
# Set to 0 to disable
INTERVAL=60

# Choose own queue for sync jobs
# Uppercase letters will at let behave like batch
QUEUE=S


# Start logfile
touch $HOME/rsync.log
echo "started local sync: $(date)" | tee $HOME/rsync.log

# Notify function
notify () {
	if [ -x /usr/bin/notify-send ]; then
		notify-send \
			-h int:transient:1 \
			-a "rsync" \
			-c "transfer" \
			-i "/usr/share/icons/gnome/256x256/actions/appointment.png" \
			-u low -t 60000 \
			"$1" "$2"
	fi
}

notify "Syncronization started" "excluding:\n$(cat ~/rsync.exclude)"

# Start the Local Syncronisation
/usr/bin/time \
	-a -o $HOME/rsync.log \
	-f "secs elapsed: %e" \
nice --adjustment=$NICENESS \
rsync \
	--human-readable \
	--exclude-from=$HOME/rsync.exclude \
	--max-size=${MAX_SIZE}m \
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

# Resync logfile
scp -q $HOME/rsync.log $HOST:$HOME/backup/

notify "Local syncronisation completed" "$(tail -n16 ~/rsync.log)"

echo "started remote sync: $(date)" | tee -a $HOME/rsync.log

# Start remote syncronisation
ssh -T $HOST <<-ENDSSH
killall --quiet rsync
rsync \
	--human-readable \
	--archive \
	--xattrs \
	--delete \
	--executability \
	--links \
	--compress \
	--out-format=%f \
	--stats \
	--bwlimit=300 \
	--max-size=${MAX_SIZE_REMOTE}m \
	$HOME/backup/ lux:/backup/$USER > rsync.log &
disown
#while ps --pid $RSYNC_PID > /dev/null; do sleep 0.1; done
ENDSSH

notify "Remote syncronisation completed" "$(tail -n16 ~/rsync.log)"

# Prune queue
JOBS=$(atq -q ${QUEUE} | cut -f 1 | xargs)
if [ -n "${JOBS}" ]; then
	atrm ${JOBS}
fi

# Schedule next run
if [ ${INTERVAL} -ne 0 ]; then
	echo -n "next syncronisation: "
	echo $0 | at -q ${QUEUE} "now + ${INTERVAL} minutes" 2>&1 | tail -n +2
fi
