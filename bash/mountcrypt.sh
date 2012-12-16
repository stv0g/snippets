#!/bin/bash
gpg -d /media/STEFFEN-KEY/.secret/luks.key.enc | sudo pmount -p - $1 $2
