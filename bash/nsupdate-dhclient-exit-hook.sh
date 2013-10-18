#!/bin/bash
##
 # dhclient wrapper to update your dns
 #
 # @copyright   2013 Steffen Vogel
 # @license     http://www.apache.org/licenses/LICENSE-2.0 Apache License 2.0
 # @author      Steffen Vogel <post@steffenvogel.de>
 # @link        http://www.steffenvogel.de
 ##
##
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 # or implied. See the License for the specific language governing
 # permissions and limitations under the License.
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
