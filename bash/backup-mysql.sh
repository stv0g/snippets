#!/bin/bash
##
 # Backup mySQL databases in separate sql dumps
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

set -e

function usage {
	cat <<-EOF
		Usage: $(basename $0) [-u USER] [-p PASSWORD] DIR

		   DIR is the directory for the backups (defaults to cwd)

		Options:
		  -u	mysql username
		  -p	mysql password
		  -h	show this help
		  -d	enable verbose output

		written by Steffen Vogel <post@steffenvogel.de>
	EOF
}

function deps() {
	FAILED=0
	for DEP in $*; do
		if ! which ${DEP} &>/dev/null; then
			echo -e "This script requires ${DEP} to run but it is not installed."
			((FAILED++))
		fi
	done
	return ${FAILED}
}

if ! deps mysql mysqldump; then
	echo -e "mysql tools missing!"
	echo
	usage
	exit 1
fi

# parse arguments
while getopts "u:p:hd" OPT; do
	case ${OPT} in
		p) MYSQL_PASS=${OPTARG} ;;
		u) MYSQL_USER=${OPTARG} ;;
		d) V=1 ;;
		h)
			usage
			exit 0 ;;
		*)
			usage
			exit 1
	esac
done

# clear all options and reset the command line
shift $((OPTIND-1))

# parsing backup directory
if [ -n "$1" ]; then
        DIR=$(readlink -f $1)
else
	DIR=$(pwd)
fi

# mySQL options
OPTS=""
if [ -n "$MYSQL_USER" ]; then
	OPTS+=" -u$MYSQL_USER"
fi

if [ -n "$MYSQL_PASS" ]; then
	OPTS+=" -p$MYSQL_PASS"
fi

# get all databases
DATABASES=`mysql $OPTS -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
DATE=$(date +%F_%H-%M-%S)

mkdir -p $DIR/$DATE
ln -rsfT $DIR/$DATE/ $DIR/latest

[ -z "$V" ] || echo "Starting mySQL backup: $(date)"
[ -z "$V" ] || echo "$(echo '$DATABASES' | wc -l) databases"
[ -z "$V" ] || echo "Backup directory: $DIR/$DATE"
for db in $DATABASES; do
	[ -z "$V" ] || echo -n "Dumping $db ..."
	mysqldump $OPTS --force --opt --events --databases $db | gzip > "$DIR/$DATE/$db.sql.gz"
	[ -z "$V" ] || echo -e "\b\b\binto $DIR/$DATE/$db.sql.gz ($(du -h $DIR/$DATE/$db.sql.gz | cut -f1))"
done
[ -z "$V" ] || echo "Finished mySQL backup: $(date) ($(du -hs $DIR/$DATE/ | cut -f1))"

