#!/bin/bash
##
 # Scrape Hetzners Serverbörse for good deals
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author	Steffen Vogel <post@steffenvogel.de>
 # @link	  https://www.steffenvogel.de
 ##

FILTER=$(mktemp)

cat > ${FILTER} <<EOF
	.server | map(
		select(
			.hdd_size >= 3000 and
			.ram >= 32 and
			.bandwith >= 1000 and
			.traffic == "unlimited" and
			.cpu_benchmark >= 9000 and
			(.setup_price | tonumber) == 0 and
			(.price | tonumber) <= 50 and
			(.specials | map(ascii_downcase ) | index("ssd"))
		)
	) |
	sort_by(.price | tonumber) | reverse
EOF

curl  https://www.hetzner.de/a_hz_serverboerse/live_data.json | jq -f $FILTER
