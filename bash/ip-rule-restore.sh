#!/bin/bash
##
 # Setup policy routing
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

GW_IF=bond0

for V in -4 -6; do
	IPR="ip $V rule"

	$IPR flush

	ip $V route flush table default
	if [ $V == -4 ]; then
		ip $V route add 141.98.136.128/29 dev ${GW_IF}		table default
		ip $V route add default via 141.98.136.129		table default
	else
		ip $V route add 2a09:11c0:f0:bbf0::/64 dev ${GW_IF}	table default
		ip $V route add default via 2a09:11c0:f0:bbf0::1 dev ${GW_IF} src 2a09:11c0:f0:bbf0::3 table default
	fi

	$IPR add pref 200 not fwmark 0x1000			lookup main
	$IPR add pref 240 not fwmark 0x1001			lookup dn42
	$IPR add pref 250					lookup ebgp
	$IPR add pref 300					lookup default
done
