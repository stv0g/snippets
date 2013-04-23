#!/bin/bash
gpsbabel -i geo -f $1 -o garmin -F /dev/ttyS0
