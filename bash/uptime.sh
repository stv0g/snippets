#!/bin/bash

### BEGIN INIT INFO
# Provides:          uptime
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Default-Stop:      0 1 6
# Short-Description: Log uptime of server before shutdown
### END INIT INFO

echo $(date +%s)  $(cat /proc/uptime) >> /var/log/uptime.log
