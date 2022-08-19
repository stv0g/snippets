#!/bin/bash
##
 # Backup remote machines via restic (pull)
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

set -e

if [ $# -ne 2 ]; then
        echo "Usage: $(basename $0) SOURCE REPO"
        exit 1
fi

SRC=$1
REPO=$2

RESTIC="/usr/local/bin/restic"

# Install Restic
ssh ${SRC} <<ENDSSH

export RESTIC_REPOSITORY="s3:http://moon.int.0l.de:9001/${REPO}"

if [ "${REPO}" == "mail.0l.de" ]; then
	export RESTIC_PASSWORD="Ca8vut7Y5hksuc1IkZfsrBf7ZKnHZwMYofLCWlmCPpJAMgqciwTZ5yxQUlUrii7h"
else
	export RESTIC_PASSWORD="NtogK'D~>)r%2g'{-gm#rWak<EKu1W5mri)E8/dWD|5.\NP}wC*(Q#{>*M_SiJ\i"
fi

export AWS_ACCESS_KEY_ID="restic"
export AWS_SECRET_ACCESS_KEY="akuuphieyaizieGaneocheituGhe9oreagohzie6go4Euzai8ail2do7pohRai0e"

# Install or update restic
if ! [ -x ${RESTIC} ]; then
	curl -qL https://github.com/restic/restic/releases/download/v0.9.5/restic_0.9.5_linux_amd64.bz2 | bunzip2 > ${RESTIC}
	chmod +x ${RESTIC}
else
	${RESTIC} self-update
fi

${RESTIC} version

# Check if repo exists
${RESTIC} snapshots || ${RESTIC} init

# Start backup
${RESTIC} -vv backup --one-file-system --exclude=/var/log/lastlog /

ENDSSH
