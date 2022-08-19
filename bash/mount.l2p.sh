#!/bin/bash
##
 # Mount MS Sharepoint folders of the RWTH L²P System in gvfs
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
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
	read -p "user: " L2P_USER
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
		echo -e "invalid format!"
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
