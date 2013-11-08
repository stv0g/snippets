#!/bin/bash
##
 # Sync with remote server and create btrfs snapshots
 #
 # This scripts uses rsync to sync remote directories with a local copy
 # After every successful sync a readonly btrfs snapshot of this copy is
 # created
 #
 # This script requires root privileges! Consider using public key auth-
 # entification with SSH and allow root logins only with a private key:
 #
 # On remote side:
 #  echo "PermitRootLogin without-password" >> /etc/ssh/sshd_config:
 #
 # On local side:
 #  sudo ssh-keygen
 #  sudo cat /root/.ssh/id_dsa.pub | ssh user@remote 'cat >> /root/.ssh/authorized_keys'
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

function usage {
        echo "Usage: $(basename $0) REMOTE LOCAL"
        echo
        echo "   REMOTE  a rsync source path/server"
	echo "   LOCAL   the local destination directory"
        exit 1
}

set -e

if [ $# -ne 2 ]; then
        usage
fi

HOST=$1
DIR=$2

DATE=$(date +%F_%H-%M-%S)
EXCLUDE=/dev,/proc,/sys,/tmp,/run,/mnt,/media,/lost+found

# sync with remote
rsync -aAX --delete root@$HOST:/ $DIR/latest --exclude={$EXCLUDE}

# create new readonly snapshot
btrfs subvolume snapshot -r $DIR/latest $DIR/$DATE
