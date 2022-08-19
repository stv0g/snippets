#!/usr/bin/env bash
# You'll need to enable IPMI over lan in idrac first
# iDRAC Settings -> Network -> IPMI Settings
# Channel Privilege Level Limit needs to be Administrator
# You may want to create a dedicated username/pass with IPMI permission in iDRAC Settings -> User Authentication

# See also: https://www.spxlabs.com/blog/2019/3/16/silence-your-dell-poweredge-server

IPMIHOST=169.254.0.1
IPMIUSER=root
IPMIPW=XXXXX # Please change
IPMIEK=XXXXX # Please change

FANSPEEDHEX=${1:-0x08} # See https://i.imgur.com/u1HMyqI.png
MAXTEMP=60
HYSTERESIS=5

FANFILE=/var/run/autofan

function ipmi() {
	ipmitool -I lanplus -H "$IPMIHOST" -U "$IPMIUSER" -P "$IPMIPW" -y "$IPMIEK" $@
}

# For R710, which doesn't have cpu temps, try this line instead:
# if ! TEMPS=$(ipmi sdr type temperature | grep -i inlet | grep -Po '\d{2,3}' 2> /dev/null);
# thanks @bumbaclot
if ! TEMPS=$(ipmi sdr type temperature | grep -vi inlet | grep -vi exhaust | grep -Po '\d{2,3}' 2> /dev/null); then
	echo "FAILED TO READ TEMPERATURE SENSOR!" >&2
	logger -t "fanctl" -p user.err -i "Error: Could not read temperature sensor"
fi

HIGHTEMP=0
LOWTEMP=1

echo "Temps: ${TEMPS}"

for TEMP in $TEMPS; do
	if [[ $TEMP > $MAXTEMP ]]; then
		HIGHTEMP=1
	fi
	if [[ $TEMP > $(($MAXTEMP - $HYSTERESIS)) ]]; then
		LOWTEMP=0
	fi
done

if [[ -r "$FANFILE" ]]; then
	AUTO=$(< "$FANFILE")
else
	AUTO=1
fi

echo "Low: ${LOWTEMP}"
echo "High: ${HIGHTEMP}"

if [[ $HIGHTEMP == 1 ]]; then
	# Automatic fan control
	ipmi raw 0x30 0x30 0x01 0x01 >& /dev/null || echo "FAILED TO SET FAN CONTROL MODE" >&2; exit 1
	echo "1" > "$FANFILE"
	if [[ $AUTO == 0 ]]; then
		logger -t "fanctl" -p user.info -i "Setting fan control to automatic"
	fi
elif [[ $LOWTEMP == 1 ]]; then
	# Manual fan control
	ipmi raw 0x30 0x30 0x01 0x00 >& /dev/null || echo "FAILED TO SET FAN CONTROL SPEED" >&2
	ipmi raw 0x30 0x30 0x02 0xff "$FANSPEEDHEX" >& /dev/null || echo "FAILED TO SET FAN SPEED" >&2
	echo "0" > "$FANFILE"
	if [[ $AUTO == 1 ]]; then
		logger -t "fanctl" -p user.info -i "Setting fan control to manual"
	fi
fi
