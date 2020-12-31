#!/bin/bash
##
 # Load ZFS encryption keys
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      http://www.steffenvogel.de
 ##

# Set IFS to a newline:
IFS="
"

for dataset in $(zfs list -H -p -o name,encryptionroot | \
    awk -F "\t" '{if ($1 == $2) { print $1 }}')
do
    if [ "$(zfs get -H -p -o value keylocation "$dataset")" = "prompt" ] &&
       [ "$(zfs get -H -p -o value keystatus "$dataset")" = "unavailable" ]
    then
        systemd-ask-password --id="zfs:$dataset" \
            "Enter passphrase for '$dataset':" | \
            zfs load-key "$dataset"
    fi
done
