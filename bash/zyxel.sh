#!/bin/bash
##
 # reconnect zyxel prestige router
 #
 # @copyright	2012 Steffen Vogel
 # @license	http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author	Steffen Vogel <info@steffenvogel.de>
 # @link	http://www.steffenvogel.de
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

IP=192.168.1.1
USER=admin

# change password here
#PW=
 
OLD_IP=`wget http://checkip.dyndns.org/ -O /dev/stdout 2&gt;/dev/null | sed "s/.*Current IP Address: \([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/"`
echo "Alte IP: $OLD_IP"
curl http://$USER:$PW@$IP/Forms/DiagADSL_1 -d "LineInfoDisplay=&amp;DiagDSLDisconnect=PPPoE+Trennung"
NEW_IP=`wget http://checkip.dyndns.org/ -O /dev/stdout 2&gt;/dev/null | sed "s/.*Current IP Address: \([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/"`
echo "Neue IP: $NEW_IP"
