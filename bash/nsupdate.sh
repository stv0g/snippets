#!/bin/bash
##
 # Bind9 nsupdate wrapper
 #
 # @copyright 2013, Andrew Leonard
 # @license   http://www.apache.org/licenses/LICENSE-2.0 Apache License 2.0
 # @author    Andrew Leonard <sysadmin@andyleonard.com>
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##


function usage {
	echo "Usage: $0 CMD [FLAGS] HOST"
	echo
	echo "  HOST is the hostname you want to update"
	echo
	echo "  CMD is one of:"
	echo "     add, delete, update"
	echo
	echo "  FLAGS are:"
	echo "     -n nameserver - DNS server to send updates to"
	echo "     -k file - Path to private key file"
	echo "     -y [hmac:]keyname:secret - key supplied via cli"
	echo "     -z zone - Zone to update"
	echo "     -t type - Record type; default is determined by -i,-4,-6 option"
	echo "     -d data - Record data / IP address"
	echo "     -i interface - Use the address of this interface as record data"
	echo "     -T ttl - Time to live for updated record; default: 1h."
	echo "     -4 / -6 use IP version"
	exit 1
}

# parsing cmd
if [ "$1" == "add" -o "$1" == "delete" -o "$1" == "update" ]; then
        CMD=$1
else
	echo -e "missing/invalid command"
	echo
	usage
fi

shift 1

# default options
NS=localhost
TTL=3600
OPTS=
VER=4

# parse arguments
while getopts "n:k:y:T:i:t:z:46" OPT ; do
	case $OPT in
		n) NS=$OPTARG ;;
		k) KEYFILE=$OPTARG ;;
		y) KEY=$OPTARG ;;
		d) RDATA=$OPTARG ;;
		t) TYPE=$OPTARG ;;
		T) TTL=$OPTARG ;;
		z) ZONE=$OPTARG ;;
		i) IF=$OPTARG ;;
		4) VER=4 ;;
		6) VER=6 ;;
		*) usage ;;
	esac
done

# clear all options and reset the command line
shift $((OPTIND-1))

# parsing host
if [ -n "$1" ]; then
	HOST=$1
else
	echo -e "missing host"
	echo
	usage
fi

if [ -n "$KEYFILE" ] ; then
	OPTS="-k $KEYFILE"
elif [ -n "$KEY" ] ; then
	OPTS="-y $KEY"
fi

if [ -z "$ZONE" ] ; then
	echo -e "missing zone"
	echo
	usage
fi

if [ -z "$TYPE" ] ; then
	case $VER in
		4) TYPE=A ;;
		6) TYPE=AAAA ;;
		*)
			echo "type missing"
			usage
	esac
fi

# get current IPv4/6 address from net or interface
if [ -z "$RDATA" ] ; then
	if [ -z "$IF" ] ; then
		RDATA=$(curl -s 'http://checkip.dyndns.org' | sed 's/.*Current IP Address: \([0-9\.]\{7,15\}\).*/\1/')
	else
		RDATA=$(ip -o -$VER address show dev $IF | sed -nr 's/.*inet6? ([^/ ]+).*/\1/p')
	fi

fi

OPTS="$OPTS -v"

# update zone
case $CMD in
	add)
		nsupdate $OPTS <<EOF
			server $NS
			zone $ZONE
			update add $HOST $TTL $TYPE $RDATA
			show
			send
EOF
		exit ;;
	delete)
		nsupdate $OPTS <<EOF
			server $NS
			zone $ZONE
			update delete $HOST $TYPE
			show
			send
EOF
		exit ;;
	update)
		nsupdate $OPTS <<EOF
			server $NS
			zone $ZONE
			update delete $HOST $TYPE
			update add $HOST $TTL $TYPE $RDATA
			show
			send
EOF
		exit ;;
	*)
		echo -e "invalid command"
		echo
		usage ;;
esac
