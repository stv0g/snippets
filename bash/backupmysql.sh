#!/bin/bash
##
 # Backup all mySQL databases
 #
 # @copyright   2013 Steffen Vogel
 # @license     http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author      Steffen Vogel <info@steffenvogel.de>
 # @link        http://www.steffenvogel.de
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

TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S")
BACKUP_DIR="/backup/mysql/$TIMESTAMP"
MYSQL_USER="backup"
MYSQL=/usr/bin/mysql
MYSQL_PASSWORD="password"
MYSQLDUMP=/usr/bin/mysqldump

DATABASES=`$MYSQL -u$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`

mkdir -p $BACKUP_DIR
for db in $DATABASES; do
	$MYSQLDUMP --force --opt --user=$MYSQL_USER -p$MYSQL_PASSWORD --events --databases $db | gzip > "$BACKUP_DIR/$db.gz"
done


