#!/bin/bash
gpsbabel -w -t -r -i kml -f /home/steffen/.googleearth/pc2gps.kml -o garmin -F /dev/ttyS0
