#!/bin/bash
##
 # Reconnect Zyxel Prestige Router
 #
 # @copyright 2021, Steffen Vogel
 # @license	http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author	Steffen Vogel <post@steffenvogel.de>
 # @link	https://www.steffenvogel.de
 ##

IP=192.168.1.1
USER=admin
PW=XXXXX # Change me
 
OLD_IP=`wget http://checkip.dyndns.org/ -O /dev/stdout 2&gt;/dev/null | sed "s/.*Current IP Address: \([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/"`
echo "Alte IP: $OLD_IP"

curl http://$USER:$PW@$IP/Forms/DiagADSL_1 -d "LineInfoDisplay=&amp;DiagDSLDisconnect=PPPoE+Trennung"

NEW_IP=`wget http://checkip.dyndns.org/ -O /dev/stdout 2&gt;/dev/null | sed "s/.*Current IP Address: \([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/"`
echo "Neue IP: $NEW_IP"
