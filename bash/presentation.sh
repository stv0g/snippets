#/bin/bash

gksudo modprobe uinput
wminput -c /etc/cwiid/wminput/presentation &
openoffice.org -show /home/steffen/Schule/Informatik/Künstliche\ Intelligenz/Künstliche\ Intelligenz.odp
