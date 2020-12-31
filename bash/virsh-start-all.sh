#!/bin/bash
##
 # Start all libvirt VMs
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      http://www.steffenvogel.de
 ##

for VM in $(virsh list --inactive --name); do
	virsh start ${VM}
done
