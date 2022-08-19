#!/bin/bash
##
 # dhclient wrapper to update your dns
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.apache.org/licenses/LICENSE-2.0 Apache License 2.0
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 #
 # Add this file to /etc/dhcp/dhclient-exit-hooks.d/nsupdate
 # to update your dns autmatically when you get a new DHCP/IP lease from your ISP
 ##

NS=/usr/local/bin/nsupdate.sh
key=/etc/bind/dhcp.key
zone=0l.de
host=wg.0l.de
server=127.0.0.1

case $reason in
	BOUND|RENEW|REBIND|TIMEOUT)
		$NS update -d $new_ip_address -k $key -z $zone -n $server -i $interface $host ;;
	RELEASE)
		$NS delete -d $old_ip_address -k $key -z $zone -n $server $host ;;
esac
