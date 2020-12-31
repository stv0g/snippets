#!/bin/bash
##
 # dyndns-update update script
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      http://www.steffenvogel.de
 ##

# default options
VER=4
SECRET=bx8qNQAnGic9OnFuqQu9XjG2NS9ed1fOaDds53R2jbq59m1WKWH3Rd1S3nijZ87u
ZONE=dyn.0l.de
HOST=$(hostname)

function usage {
	cat <<-EOF
		Usage: $0 [-4,-6] [-s SECRET] [-z ZONE] [-d] [-D] [HOST]

		Options:
		  -s	is the secret from the webservice otherwise prompted
		  -z	nameserver zone
		  -4	update A record (default)
		  -6	update AAAA record
		  -D	live monitor interface for changing addresses
		  -d	enable verbose output
		  -h	show this help

		  HOST is the hostname which you want to update
		    defaults to the local hostname

		Example: $0 -6 -z dyn.0l.de sea

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

function update() {
	RDATA=$1

	WAIT=1
	URL="https://dyndns.k8s.0l.de/update?secret=${SECRET}&domain=${HOST}&addr=${RDATA}"

	while true; do
		if (( $DEBUG )); then echo "Updating record: ${URL}"; fi
		CODE=$(curl -w %{http_code} -s -o /dev/stderr "${URL}") 2>&1

		if [ ${CODE} -eq 0 ]; then
			if (( ${DEBUG} )); then echo "Sleeping for ${WAIT} secs..."; fi
			sleep ${WAIT} # wait until interface is ready
			WAIT=$((${WAIT}*2))
		elif [ ${CODE} -ge 500 ]; then
			if (( ${DEBUG} )); then echo "Request failed. Aborting.."; fi
			return 1
		else
			return 0
		fi
	done
}

function get() {
	curl -${VER} -s http://ident.me
}

# check dependencies
if ! deps dig curl ip; then
	echo -e "Unmet dependencies: Aborting!"
	exit 1
fi

# parse arguments
while getopts "z:p:u:t:i:Dhd46" OPT; do
	case ${OPT} in
		s) SECRET=${OPTARG} ;;
		4) VER=4 ;;
		6) VER=6 ;;
		D) DAEMON=1 ;;
		z) ZONE=${OPTARG} ;;
		d) DEBUG=${OPTARG:-5} ;;
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

# parsing host
if [ -n "$1" ]; then
	HOST=$1
else
	echo -e "missing host"
	exit 1
fi

# prompting for secret
if [ -z "${SECRET}" ]; then
	read -s -p "secret: " SECRET
	echo
fi

IP=$(get)
if [ -n "${IP}" ]; then
	update "${IP}" "${TYPE}" || exit
else
	echo -e "failed to get ip from net"
	exit 1
fi
