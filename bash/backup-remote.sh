#!/bin/bash
##
 # Sync with remote server and create Btrfs snapshots
 #
 # This scripts uses rsync to sync remote directories with a local copy
 # After every successful sync a readonly Btrfs snapshot of this copy is
 # created
 #
 # This script requires root privileges for creating Btrfs snapshots.
 # Consider using public key authentification with SSH to allow root
 # logins on remote machines:
 #
 # On remote side:
 #  echo "PermitRootLogin without-password" >> /etc/ssh/sshd_config:
 #
 # On local side:
 #  sudo ssh-keygen
 #  sudo cat /root/.ssh/id_dsa.pub | ssh user@remote 'cat >> /root/.ssh/authorized_keys'
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

function usage {
	echo "Usage: $(basename $0) SOURCE DEST"
	echo
	echo "  SOURCE  a path to the subvolume to backup"
	echo "  DEST    a path to the backup destination"
	exit 1
}

set -e

if [ $# -ne 2 ]; then
	echo -e "invalid args!"
	echo
	usage
fi

DATE=$(date +%F_%H-%M-%S)

SRC=$1
DEST=$(readlink -f $2)

if ! btrfs sub show $DEST/.current &> /dev/null; then
	if [ -d $DEST/.current ]; then
		echo -e "destination directory exists and is not a valid btrfs subvolume!"
		echo
		usage
	else
		btrfs sub create $DEST/.current
	fi
fi

# rsync options
OPTS="--archive --acls --xattrs"
#OPTS+=" --progress --human-readable"
OPTS+=" --delete --delete-excluded"
OPTS+=" --exclude /dev/"
OPTS+=" --exclude /proc/"
OPTS+=" --exclude /sys/"
OPTS+=" --exclude /tmp/"
OPTS+=" --exclude /run/"
OPTS+=" --exclude /mnt/"
OPTS+=" --exclude /media/"
OPTS+=" --exclude /lost+found/"

# sync with remote
rsync $OPTS $SRC $DEST/.current/

# create new readonly snapshot
btrfs subvolume snapshot -r $DEST/.current $DEST/$DATE

# create symlink to latest snapshot
ln -rsfT $DEST/$DATE $DEST/latest
