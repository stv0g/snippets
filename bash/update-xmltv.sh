#!/bin/bash
##
 # Update XMLTV data between Emby and TVHeadEnd
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

tv_grab_eu_epgdata --output /srv/Data/Emby/epgdata.xml
tv_grab_eu_xmltvse --output /srv/Data/Emby/xmltvse.xml

cat /srv/Data/Emby/epgdata.xml | socat - UNIX-CONNECT:/var/lib/tvheadend/config/epggrab/xmltv.sock
cat /srv/Data/Emby/xmltvse.xml | socat - UNIX-CONNECT:/var/lib/tvheadend/config/epggrab/xmltv.sock
