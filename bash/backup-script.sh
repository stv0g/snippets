#!/bin/bash
##
 # System Backupscript
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      https://www.steffenvogel.de
 ##

#=============================================================
# Haupt Einstellungen
#============================================================= 

# Hostname oder IP Adresse des Servers
HOST=localhost

# Backup Verzeichnisse
BACKUPDIR="/backup"   
MYSQL_BACKUPDIR="/backup/mysql"
DATA_BACKUPDIR="/backup/data"

# Wochentag f�r w�chentliche Backups (1-7; 1 steht f�r Montag)
DOWEEKLY=5

# Kompressionsmethode (gzip oder bzip2)
COMP=gzip

# Befehl vor dem Backup
#PREBACKUP="/etc/backup-pre"

# Befehl nach dem Backup
#POSTBACKUP="/etc/backup-post" 

#=============================================================
# Logging Einstellungen
#=============================================================
if [ "$HOST" = "localhost" ]; then
	HOST=`hostname`
fi

# Logfiles 
LOGFILE=$BACKUPDIR/$HOST-`date +%N`.log
LOGERR=$BACKUPDIR/ERRORS_$HOST-`date +%N`.log

#=============================================================
# Mail Einstellungen
#============================================================= 

# Was soll gemailt werden?
# - log   : sendet das Logfile per Mail
# - files : sendet das Logfile und die SQL Dumps per Mail
# - stdout : deaktiviert Mail und gibt per stdout aus
# - quiet : sendet nur Error Logs per Mail
MAIL_CONTENT="stdout"

# Maximale Gr��e des Mail Anhangs
MAIL_MAXATTSIZE="4000"

# Mail Adresse
MAIL_ADDR="admin@localhost"

#=============================================================
# FTP Einstellungen
#============================================================= 

# FTP Benutzer
FTP_USERNAME=yourftpusername

# FTP Passwort f�r $FTP_USERNAME
FTP_PASSWORD=yourftppassword

# Hostname oder IP Adresse des FTP Servers
FTP_HOST=yourftpserver

#=============================================================
# Daten Einstellungen
#=============================================================

# Liste der t�glichen Backupverzeichnisse (durch " " getrennt)
DATA_DIRNAMES="/home /opt/mails /etc"

# Liste der w�chentlichen Backupverzeichnisse (durch " " getrennt)
DATA_WDIRNAMES="/var/www $DATA_DIRNAMES"

# Liste der monatlichen Backupverzeichnisse (durch " " getrennt)
DATA_MDIRNAMES="/opt /var/ftp $DATA_WDIRNAMES"

# Exclude Datei
DATA_EXCLUDELIST="/etc/backup_exclude"

# tar Parameter (siehe "man tar")
TARFLAGS="--create --preserve-permissions --dereference --ignore-failed-read --exclude-from=$DATA_EXCLUDELIST --file"


#=============================================================
# mySQL Einstellungen
#=============================================================

# mySQL Benutzer
MYSQL_USERNAME=yourmysqlusername

# mySQL Passwort f�r $MYSQL_USERNAME
MYSQL_PASSWORD=yourmysqlpassword

# Hostname oder IP Adresse des mySQL Servers
MYSQL_HOST=$HOST

# Liste der t�glichen Backupdatenbanken (durch " " getrennt; "all" f�r alle Datenbanken)
MYSQL_DBNAMES="all"

# Liste der w�chentlichen Backupdatenbanken (durch " " getrennt)
MYSQL_WDBNAMES=$MYSQL_DBNAMES

# Liste der monatlichen Backupdatenbanken (durch " " getrennt)
MYSQL_MDBNAMES="$MYSQL_WDBNAMES"

# Datenbanken zum Excluden
MYSQL_DBEXCLUDE=""

# CREATE DATABASE zu den mySQL Dumps hinzuf�gen?
MYSQL_CREATE_DATABASE=yes

# Komprimierte Verbindung zum mySQL Server
MYSQL_COMMCOMP=no

# Maximale Gr��e des Verbindungspuffer zum mySQL Server (Maximum 1GB)
MYSQL_MAX_ALLOWED_PACKET=

# Socketadresse des mySQL Server bei localhost Verbindungen
MYSQL_SOCKET=

# mysqldump Parameter (siehe "man mysqldump")
MYSQL_OPT="--quote-names --opt"

#=====================================================================
# Konfiguration Ende
#=====================================================================

PATH=/usr/local/bin:/usr/bin:/bin
DATE=`date +%Y-%m-%d_%Hh%Mm`		# Datum e.g 2002-09-21
DOW=`date +%A`						# Tag der Woche z.B Montag
DNOW=`date +%u`						# Tag der Woche z.B 1
DOM=`date +%d`						# Tag des Monats z.B 23
M=`date +%B`						# Monat z.B Januar
W=`date +%V`						# Wochen Nummer z.B 37

MYSQL_BACKUPFILES=""
DATA_BACKUPFILES=""

if [ "$HOST" = `hostname` ]; then
	if [ "$MYSQL_SOCKET" ]; then
		MYSQL_OPT="$MYSQL_OPT --socket=$MYSQL_SOCKET"
	fi
fi

# Komprimierte Verbindung zum mySQL Server
if [ "$MYSQL_COMMCOMP" = "yes" ];
	then
		MYSQL_OPT="$OPT --compress"
fi

# Maximale Gr��e des Verbindungspuffer zum mySQL Server (Maximum 1GB)
if [ "$MYSQL_MAX_ALLOWED_PACKET" ];
	then
		MYSQL_OPT="$MYSQL_OPT --max_allowed_packet=$MYSQL_MAX_ALLOWED_PACKET"
fi

# Ben�tigte Verzeichnisse erstellen
if [ ! -e "$BACKUPDIR" ]
	then
	mkdir -p "$BACKUPDIR"
fi


# Logging aktivieren
touch $LOGFILE
exec 6>&1           # Link file descriptor #6 with stdout.
                    # Saves stdout.
exec > $LOGFILE     # stdout replaced with file $LOGFILE.
touch $LOGERR
exec 7>&2           # Link file descriptor #7 with stderr.
                    # Saves stderr.
exec 2> $LOGERR     # stderr replaced with file $LOGERR.


# Funktionen

# FTP Transfer
ftptrans () {
	wput -N $BACKUPDIR
	return 0
}

# Display Funktion
display () {
	case "$1" in
		prebackup)
			echo "Prebackup Ausgabe."
			echo
			eval $PREBACKUP
			echo
			display dl
			;;
	
		postbackup)
			echo "Postbackup Ausgabe."
			echo
			eval $POSTBACKUP
			echo
			display dl
			;;
	
		start)
			echo ======================================================================
			echo System Backup
			echo 
			echo Backup des Servers: $HOST
			display dl
			;;
	
		end)
			echo Backup Ende `date`
			echo ======================================================================
			echo Ben�tigter Speicherplatz f�r Backups:
			echo Data : `du -hs "$DATA_BACKUPDIR"`
			echo mySQL: `du -hs "$MYSQL_BACKUPDIR"`
			echo All  : `du -hs "$BACKUPDIR"`
			display dl
			;;
	
		mysqlstart)
			echo  starte mySQL Backup: `date`
			display dl
			;;
	
		mysqlend)
			echo  beende mySQL Backup: `date`
			display dl
			;;
	
		datastart)
			echo  starte Data Backup: `date`
			display dl
			;;
	
		dataend)
			echo  beende Data Backup: `date`
			display dl
			;;
	
		dl)
			echo ======================================================================
			echo
			;;
	
		l)
			echo ----------------------------------------------------------------------
			;;
	esac
	
	return 0
}

# Datenbank Dump
dbdump () {
	mysqldump --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD --host=$MYSQL_HOST $MYSQL_OPT $1 > $2
return 0
}

# Archivierungs Funktion
archive () {
	echo "Archiving $2"
	tar $TARFLAGS "$1" "$2" 2>&1 | grep -v "tar: Removing leading"
	echo "Archived in $1"
	return 0
}

# Kompressions Funktion
	SUFFIX=""
	compression () {
	if [ "$COMP" = "gzip" ]; then
		gzip -f "$1"
		echo Backup Information for "$1"
		gzip -l "$1.gz"
		SUFFIX=".gz"
	elif [ "$COMP" = "bzip2" ]; then
		echo Komprimierungs Informationen f�r "$1.bz2"
		bzip2 -f -v $1 2>&1
		SUFFIX=".bz2"
	else
		echo "Keine Kompressionsmethode gew�hlt!"
	fi
	return 0
}

# Soll CREATE_DATABASE hinzugef�gt werden?
if [ "$MYSQL_CREATE_DATABASE" = "no" ]; then
	MYSQL_OPT="$MYSQL_OPT --no-create-db"
else
	MYSQL_OPT="$MYSQL_OPT --databases"
fi

# W�hle alle Datenbanken aus
if [ "$MYSQL_DBNAMES" = "all" ]; then
	MYSQL_DBNAMES="`mysql --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD --host=$MYSQL_HOST --batch --skip-column-names -e "show databases"| sed 's/ /%/g'`"

	# Schließe Datenbanken aus
	for exclude in $MYSQL_DBEXCLUDE
	do
		MYSQL_DBNAMES=`echo $MYSQL_DBNAMES | sed "s/\b$exclude\b//g"`
	done

	MYSQL_MDBNAMES=$MYSQL_DBNAMES
fi

display start					# Zeige Start Informationen

# Prebackup
if [ "$PREBACKUP" ]; then
	display "prebackup"			# Zeige Prebackup Ausgabe
fi

#================================================	
# Monatliches Backup
#================================================	
if [ $DOM = "01" ]; then

# Erstellen ben�tigte Verzeichnisse
if [ ! -e "$MYSQL_BACKUPDIR/monthly/$M" ]
	then
	mkdir -p "$MYSQL_BACKUPDIR/monthly/$M"
fi

if [ ! -e "$DATA_BACKUPDIR/monthly/$M" ]
	then
	mkdir -p "$DATA_BACKUPDIR/monthly/$M"
fi

# mySQL
display mysqlstart
for MYSQL_MDB in $MYSQL_MDBNAMES
do

	# Bereite $MYSQL_MDB vor
	MYSQL_MDB="`echo $MYSQL_MDB | sed 's/%/ /g'`"
	
	echo Monthly Backup of $MYSQL_MDB...
	display l
	dbdump "$MYSQL_MDB" "$MYSQL_BACKUPDIR/monthly/$M/${MYSQL_MDB}_$DATE.$M.$MYSQL_MDB.sql"
	compression "$MYSQL_BACKUPDIR/monthly/$M/${MYSQL_MDB}_$DATE.$M.$MYSQL_MDB.sql"
	MYSQL_BACKUPFILES="$BACKUPFILES $MYSQL_BACKUPDIR/monthly/$M/${MYSQL_MDB}_$DATE.$M.$MYSQL_MDB.sql$SUFFIX"
	display dl
done

display mysqlend
display datastart

# Daten
for DATA_MDIR in $DATA_MDIRNAMES
do

	# Bereite $DATA_MDIR f�r den Dateinamen vor
	DATA_MDIR_DISP="`echo $DATA_MDIR | cut -b 2- | sed 's/\//_/g' | sed 's/ //g'"
	
	echo Monthly Backup of $DATA_MDIR...
	display l
	archive "$DATA_BACKUPDIR/monthly/$M/${DATA_MDIR_DISP}_$DATE.$M.tar" "$DATA_MDIR"
	display l
	compression "$DATA_BACKUPDIR/monthly/$M/${DATA_MDIR_DISP}_$DATE.$M.tar"
	DATA_BACKUPFILES="$DATA_BACKUPFILES $DATA_BACKUPDIR/monthly/$M/${DATA_MDIR_DISP}_$DATE.$M.tar$SUFFIX"
	display dl
done
display dataend

fi


#================================================	
# W�chentliches Backup
#================================================	
if [ $DNOW = $DOWEEKLY ]; then

# Erstellen ben�tigte Verzeichnisse
if [ ! -e "$MYSQL_BACKUPDIR/weekly/week_$W" ]
	then
	mkdir -p "$MYSQL_BACKUPDIR/weekly/week_$W"
fi

if [ ! -e "$DATA_BACKUPDIR/weekly/week_$W" ]
	then
	mkdir -p "$DATA_BACKUPDIR/weekly/week_$W"
fi

# L�sche alte Backups
echo Rotating 5 weeks Backups...
display dl
if [ "$W" -le 05 ];then
	REMW=`expr 48 + $W`
elif [ "$W" -lt 15 ];then
	REMW=0`expr $W - 5`
else
	REMW=`expr $W - 5`
fi
eval rm -fv "$MYSQL_BACKUPDIR/weekly/week_$REMW/*" 
eval rm -fv "$DATA_BACKUPDIR/weekly/week_$REMW/*" 

# mySQL
display mysqlstart
for MYSQL_WDB in $MYSQL_WDBNAMES
do

	# Prepare $DB for using
	MYSQL_WDB="`echo $MYSQL_WDB | sed 's/%/ /g'`"
	
	echo Weekly Backup of Database \( $MYSQL_WDB \)
	display l
	dbdump "$MYSQL_WDB" "$MYSQL_BACKUPDIR/weekly/week_$W/${MYSQL_WDB}_week.$W.$DATE.sql"
	compression "$MYSQL_BACKUPDIR/weekly/week_$W/${MYSQL_WDB}_week.$W.$DATE.sql"
	MYSQL_BACKUPFILES="$MYSQL_BACKUPFILES $MYSQL_BACKUPDIR/weekly/week_$W/${MYSQL_WDB}_week.$W.$DATE.sql$SUFFIX"
	display dl
done

display mysqlend
display datastart

# Daten

for DATA_WDIR in $DATA_WDIRNAMES
do
	# Bereite $DATA_WDIR f�r den Dateinamen vor
	DATA_DIR_DISP="`echo $DATA_WDIR | cut -b 2- | sed 's/\//_/g' | sed 's/ //g'"
	
	echo Weekly Backup of $DATA_WDIR...
	display l
	archive "$DATA_BACKUPDIR/weekly/week_$W/${DATA_WDIR_DISP}_$DATE.$W.tar" "$DATA_WDIR"
	display l
	compression "$DATA_BACKUPDIR/weekly/week_$W/${DATA_WDIR_DISP}_$DATE.$W.tar"
	DATA_BACKUPFILES="$DATA_BACKUPFILES $DATA_BACKUPDIR/weekly/week_$W/${DATA_WDIR_DISP}_$DATE.$W.tar$SUFFIX"
	display dl
done
display dataend

fi

#================================================	
# T�gliches Backup
#================================================		
# Erstellen ben�tigte Verzeichnisse
if [ ! -e "$MYSQL_BACKUPDIR/daily/$DOW" ]
	then
	mkdir -p "$MYSQL_BACKUPDIR/daily/$DOW"
fi

if [ ! -e "$DATA_BACKUPDIR/daily/$DOW" ]
	then
	mkdir -p "$DATA_BACKUPDIR/daily/$DOW"
fi

# L�sche alte Backups
echo Rotating last weeks Backup...
display l
eval rm -fv "$MYSQL_BACKUPDIR/daily/$DOW/*" 
eval rm -fv "$DATA_BACKUPDIR/daily/$DOW/*" 
display dl

# mySQL
display mysqlstart
for MYSQL_DB in $MYSQL_DBNAMES
do
	echo Daily Backup of Database \( $MYSQL_DB \)
	display l
	dbdump "$MYSQL_DB" "$MYSQL_BACKUPDIR/daily/$DOW/${MYSQL_DB}_$DATE.$DOW.sql"
	compression "$MYSQL_BACKUPDIR/daily/$DOW/${MYSQL_DB}_$DATE.$DOW.sql"
	MYSQL_BACKUPFILES="$MYSQL_BACKUPFILES $MYSQL_BACKUPDIR/daily/$DOW/${MYSQL_DB}_$DATE.$DOW.sql$SUFFIX"
	display dl
done

display mysqlend
display datastart

# Daten

for DATA_DIR in $DATA_DIRNAMES
do
	# Bereite $DATA_DIR f�r den Dateinamen vor
	DATA_DIR_DISP="`echo $DATA_DIR  | cut -b 2- | sed 's/\//_/g' | sed 's/ //g'"
	
	echo Daily Backup of $DATA_DIR...
	display l
	archive "$DATA_BACKUPDIR/daily/$DOW/${DATA_DIR_DISP}_$DATE.$DOW.tar" "$DATA_DIR"
	display l
	compression "$DATA_BACKUPDIR/daily/$DOW/${DATA_DIR_DISP}_$DATE.$DOW.tar"
	DATA_BACKUPFILES="$DATA_BACKUPFILES $DATA_BACKUPDIR/daily/$DOW/${DATA_DIR_DISP}_$DATE.$DOW.tar$SUFFIX"
	display dl
done
display dataend


display end								# Gebe Zusammenfassung aus

# Run command when we're done
if [ "$POSTBACKUP" ]; then
	display "postbackup"				# Zeige Postbackup Ausgabe
fi

#Clean up IO redirection
exec 1>&6 6>&-      # Stelle Standartausgabe wieder her und schlie�e Datei #6
exec 1>&7 7>&-      # Stelle Standartausgabe wieder her und schlie�e Datei #7

if [ "$MAIL_CONTENT" = "files" ]
then
	if [ -s "$LOGERR" ]
	then
		# F�ge bei Fehlern Error Log hinzu
		MYSQL_BACKUPFILES="$MYSQL_BACKUPFILES $LOGERR"
		ERRORNOTE="ACHTUNG Backup Fehler: "
	fi
	# Ermittel SQL Dump Gr��e
	MAIL_ATTSIZE=`du -c $MYSQL_BACKUPFILES | grep "[[:digit:][:space:]]total$" |sed s/\s*total//`
	if [ $MAIL_MAXATTSIZE -ge $MAIL_ATTSIZE ]
	then
		BACKUPFILES=`echo "$BACKUPFILES" | sed -e "s# # -a #g"`	# enable multiple attachments
		mutt -s "$ERRORNOTE Backup Log and SQL Dump f�r $HOST - $DATE" $BACKUPFILES $MAIL_ADDR < $LOGFILE		#senden via mutt
	else
		cat "$LOGFILE" | mail -s "ACHTUNG! - SQL Dump ist zu gro� um gemailt zu werden auf $HOST - $DATE" $MAIL_ADDR
	fi
elif [ "$MAIL_CONTENT" = "log" ]
then
	cat "$LOGFILE" | mail -s "Backup Log f�r $HOST - $DATE" $MAIL_ADDR
	if [ -s "$LOGERR" ]
		then
			cat "$LOGERR" | mail -s "$ERRORNOTE Error Log f�r: $HOST - $DATE" $MAIL_ADDR
	fi	
elif [ "$MAIL_CONTENT" = "quiet" ]
then
	if [ -s "$LOGERR" ]
		then
			cat "$LOGERR" | mail -s "$ERRORNOTE Error Log f�r $HOST - $DATE" $MAIL_ADDR
			cat "$LOGFILE" | mail -s "Log f�r $HOST - $DATE" $MAIL_ADDR
	fi
else
	if [ -s "$LOGERR" ]
		then
			cat "$LOGFILE"
			echo
			echo "###### ACHTUNG ######"
			echo "Es entstanden Fehler beim Sichern des Datenbestandes"
			echo "Dazu hier nun das Error Log:"
			cat "$LOGERR"
	else
		cat "$LOGFILE"
	fi	
fi

if [ -s "$LOGERR" ]
	then
		STATUS=1
	else
		STATUS=0
fi

# L�schen der Logfiles
eval rm -f "$LOGFILE"
eval rm -f "$LOGERR"

exit $STATUS
