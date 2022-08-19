#!/bin/bash
##
 # Perform an action for all libvirt VMs
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

 ACTION=${ACTION:-start}

for VM in $(virsh list --inactive --name); do
	virsh ${ACTION} ${VM}
done
