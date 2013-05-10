#!/bin/bash
##
 # SDDNS update script
 #
 # @copyright	2013 Steffen Vogel
 # @license	http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author	Steffen Vogel <post@steffenvogel.de>
 # @link	http://www.steffenvogel.de
 ##
##
 # This file is part of sddns
 #
 # sddns is free software: you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation, either version 3 of the License, or
 # any later version.
 #
 # sddns is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 # GNU General Public License for more details.
 #
 # You should have received a copy of the GNU General Public License
 # along with sddns. If not, see <http://www.gnu.org/licenses/>.
 ##

# default options
VER=4
TTL=120
USER=anonymous
ZONE=0l.de
HOST=$(hostname)

function usage {
	cat <<-EOF
		Usage: sddns.sh [-4,-6] [-p PASS] [-t TTL] [-i IF] [-z ZONE] [-d] [-D] [HOST]

		Options:
		  -u	optional user for admin permissions
		  -p	is the password from the webservice otherwise prompted
		  -t	is the time to live in seconds
		  -i	use the ip from this nic
		  -z	nameserver zone
		  -4	update A record (default)
		  -6	update AAAA record
		  -D	live monitor interface for changing addresses
		  -d	enable verbose output
		  -h	show this help

		  HOST is the hostname which you want to update
		    defaults to the local hostname

		Example: sddns.sh -6 -t 3600 -i eth0 sea

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

function parse() {
	if [[ $* =~ ${RE} && ${BASH_REMATCH[1]} == "${IF}" ]]; then
		echo ${BASH_REMATCH[2]}
	fi
}

function update() {
	RDATA=$1
	TYPE=$2

	WAIT=1
	URL="http://d.0l.de/update.txt?host=${HOST}&zone=${ZONE}&ttl=${TTL}&class=IN&type=${TYPE}&rdata=${RDATA}&debug=${DEBUG}"

	if (( $DEBUG )); then echo "Updating record: $URL"; fi

	while true; do
		CODE=$(curl -w %{http_code} -s -o /dev/stderr -u "${USER}:${PASS}" "$URL") 2>&1

		if [ $CODE -eq 0 ]; then
			if (( $DEBUG )); then echo "Sleeping for ${WAIT} secs..."; fi
			sleep $WAIT; # wait until interface is ready
			WAIT=$(($WAIT*2))
		elif [ $CODE -ge 500 ]; then
			if (( $DEBUG )); then echo "Request failed. Aborting.."; fi
			return 1
		else
			break
		fi
	done

	return 0
}

function get() {
	curl -${VER} -s http://d.0l.de/ip.txt | cut -f 3
}

function query() {
	dig $TYPE $HOST.$ZONE @ns0.0l.de +short
}

# check dependencies
if ! deps dig curl ip sed cut; then
	echo -e "Unmet dependencies: Aborting!"
	exit 1
fi

# parse arguments
while getopts "z:p:u:t:i:Dhd46" OPT; do
	case ${OPT} in
		p)
			PASS=${OPTARG}
			;;
		u)
			USER=${OPTARG}
			;;
		t)
			TTL=${OPTARG}
			;;
		4)
			VER=4
			;;
		6)
			VER=6
			;;
		i)
			IF=${OPTARG}
			;;
		D)
			DAEMON=1
			;;
		d)
			DEBUG=${OPTARG:-5}
			;;
		h)
			usage
			exit 0
			;;
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

# prompting for password
if [ -z "${PASS}" ]; then
	read -s -p "password: " PASS
	echo
fi

# setup regular expression and record type
if [ ${VER} -eq 4 ]; then
	RE='^[0-9]+: +([^ ]+) +inet +([^/]+)/([0-9]+) brd [^ ]+ +scope +global'
	TYPE="A"
else
	RE='^[0-9]+: +([^ ]+) +inet6 +([^/]+)/([0-9]+) +scope +global'
	TYPE="AAAA"
fi

# lets go
if [ -z "${IF}" ]; then
	IP=$(get)
	if [ -n "${IP}" ]; then
		update "${IP}" "${TYPE}" || exit
	else
		echo -e "failed to get ip from net"
		exit 1
	fi
else
	while read LINE; do
		IP=$(parse ${LINE})
		if [ -n "${IP}" ]; then
			update "${IP}" "${TYPE}" || exit
		fi
	done < <(ip -o -${VER} address show && (( ${DAEMON} )) && ip -o -${VER} monitor address)
fi
