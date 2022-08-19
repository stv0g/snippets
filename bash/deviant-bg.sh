#!/bin/bash
##
 # Deviant Background Changer
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de/2009/11/28/deviantart-wallpapers/
 # @version   1.1
 ##

# Path to save downloaded images
BG_PATH="/home/steffen/backgrounds"

# RSS Feed to fetch images from
RSS="http://backend.deviantart.com/rss.xml?q=boost%3Apopular+in%3Aphotography+max_age%3A8h&type=deviation&offset=0"

# random pool size
POOL_SIZE=10

GCONF_URL="/desktop/gnome/background/picture_filename"

# checks if window manager is running
if [[ $(ps -U $(whoami) -F | grep gnome-terminal | wc -l) > 1 ]] ; then

 # get dbus socket address
 export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS= /proc/$(pgrep -u "$(whoami)" gnome-session)/environ | sed -e 's/DBUS_SESSION_BUS_ADDRESS=//')

 # fetch images
 wget --user-agent Mozilla/4.0 -q -O - "$RSS" | grep -o '<media:content url=".*" height=".*" width=".*" medium="image"/>' | grep -E -o -m 5 "http://.*\.(jpg|png|jpeg|gif)" | xargs wget -q -N -P  "$BG_PATH" --user-agent Mozilla/4.0

 # get old image
 OLD_BG=`gconftool-2 --get $GCONF_URL`
 NEW_BG=$OLD_BG

 until [[ $OLD_BG != $NEW_BG ]]; do
  # choose new image
  NEW_BG="$BG_PATH/`ls -tr1 $BG_PATH | tail -$POOL_SIZE | head -$((($RANDOM%($POOL_SIZE-1))+1)) | tail -1`"
 done

 # set new image
 gconftool-2 --type String --set $GCONF_URL "$NEW_BG"
 echo $NEW_BG
else
 echo "sry no gnome session found!"
fi
