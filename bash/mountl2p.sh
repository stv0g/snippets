#!/bin/bash
##
 # Mount MS Sharepoint folders of the RWTH L²P System in gvfs
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

function usage {
	echo "usage: mountl2p.sh [-f FORMAT] [-s SEMESTER] [-u L2P_USER] [-p L2P_PASS]"
	echo
	echo "  FORMAT is one of 'gvfs' or 'fstab'"
	echo "  SEMESTER is an optional regex to filter the semester"
	echo "  L2P_USER is your L2P account name like 'sv123242'"
	echo "  L2P_PASS is your L2P account password"
	echo
	echo "example: ./mountl2p.sh -f gvfs -s \"ws12|ss12\" >> ~/.gtk-bookmarks"
	echo
	echo "written by Steffen Vogel <post@steffenvogel.de>"
}

# parse commandline arguments
while getopts ":u:p:f:s:" OPT; do
	case ${OPT} in
		u)
			L2P_USER=${OPTARG}
			;;
		p)
			L2P_PASS=${OPTARG}
			;;
		f)
			FORMAT=${OPTARG}
			;;
		s)
			SEMESTER=${OPTARG}
			;;
		*)
			usage
			exit 1
	esac
done

# prompt for credentials
if [ -z "${L2P_USER}" ]; then
	read -p "L2P user: " L2P_USER
fi

if [ -z "${L2P_PASS}" ]; then
	read -s -p "password: " L2P_PASS
fi

# filter by semester
if [ -z "${SEMESTER}" ]; then
	SEMESTER="[sw]s[0-9]{2}"
fi

# output format
if [ -z "${FORMAT}" ]; then
	FORMAT="gvfs"
fi
case ${FORMAT} in
	fstab)
		FORMAT="https\://www2.elearning.rwth-aachen.de\1/materials/documents\t/home/${USER}/l2p/\2/\3/\tdavfs\tuser,noauto\t0\t0 # \4"
		;;
	gvfs)
		FORMAT="davs\://${L2P_USER}@www2.elearning.rwth-aachen.de\1/materials/documents L²P\:\2 \4"
		;;
	*)
		echo "invalid format!" >&2
		echo
		usage
		exit 1
esac

# start
for SECTION in summary archive; do
	URL="https://www2.elearning.rwth-aachen.de/foyer/${SECTION}/default.aspx"

	# fetch learning rooms
	curl -s -u "${L2P_USER}:${L2P_PASS}" "${URL}" | \
	sed -n -r -e "s:.*<a href=\"(/(${SEMESTER})/[0-9]{2}[sw]s-([0-9]+))/information/default\.aspx\">([^<]+)</a>.*:${FORMAT}:p"
done
