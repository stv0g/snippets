#!/bin/bash
##
 # Update ROA tables for DN42
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

set +x

curl -sfSLR {-o,-z}/var/lib/bird/bird_roa_dn42_v4.conf https://dn42.burble.com/roa/dn42_roa_bird2_4.conf
curl -sfSLR {-o,-z}/var/lib/bird/bird_roa_dn42_v6.conf https://dn42.burble.com/roa/dn42_roa_bird2_6.conf

birdc configure
