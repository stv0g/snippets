#!/bin/bash

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
