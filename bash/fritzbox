#!/bin/bash
##
 # reconnect avm fritzbox router
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

curl 'http://fritz.box:49000/upnp/control/WANIPConn1' \
 -H 'Content-Type: text/xml; charset="utf-8"' \
 -H 'SoapAction: urn:schemas-upnp-org:service:WANIPConnection:1#ForceTermination' \
 -d '<?xml version="1.0" encoding="utf-8"?> <s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"> <s:Body> <u:ForceTermination xmlns:u="urn:schemas-upnp-org:service:WANIPConnection:1" /> </s:Body> </s:Envelope>'
