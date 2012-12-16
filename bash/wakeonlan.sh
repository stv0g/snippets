#!/bin/bash
##
 # Send wake on lan packages to the LAN network
 #
 # includes MAC lookup via DNS and ARP
 #
 # @copyright	2012 Steffen Vogel
 # @license	http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author	Steffen Vogel <info@steffenvogel.de>
 # @link	http://www.steffenvogel.de/
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

IP_REGEX="[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}"

E_BADARGS=65
if [[ ! -n "$1" ]]; then
	echo "Usage: $(basename $0) HOST"
	exit $E_BADARGS
fi

if [[ $1 =~ ${IP_REGEX} ]]; then
	IP=$1
else
	IP=$(dig +short $1 | head -n1)

	if [[ -z ${IP} ]]; then
		echo "failed to lookup ip"
		exit 4
	else
		echo "$1 has ip: ${IP}"
	fi
fi


# do a ping to trigger ARP request
ping -c1 -q ${IP} &>/dev/null
if [[ $? -eq 0 ]]; then
	echo "host is alive!"
#	exit 2
fi

MAC=$(grep "^${IP}\ " /proc/net/arp | awk '{print $4}')

if [[ -z ${MAC} ]]; then
	echo "no mac found!"
	exit 1
fi

echo "$1 has mac: ${MAC}"


if [[ $(id -un) != "root" ]]; then
	echo "$(basename $0) requires root privileges!"
	exit 3
fi

etherwake ${MAC}

echo "wol packet has been sent"
