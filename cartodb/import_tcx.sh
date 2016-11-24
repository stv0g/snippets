#!/bin/bash
#
# Import your sport activities from tapiriik.com to cartoco.com.
# 
# Prerequisistes:
#   - rclone
#   - curl
#   - jq
#   - xsqlproc
#
# Author: Steffen Vogel <post@steffenvogel.de>
# Copyright: 2016, Steffen Vogel
# License: GPLv3

CARTODB_API_KEY=$(pass apis/cartodb)
CARTODB_USER=stv0g
CARTODB_EP="https://${CARTODB_USER}.carto.com/api/v2/sql?api_key=${CARTODB_API_KEY}"

TCXDIR=~/Tracks

STYLESHEET=$(mktemp)
JQFILTER=$(mktemp)

cat << EOF > ${JQFILTER}
if has("error") then
	"Error: " + .error[0]
else
	"Success: Rows added: " + (.total_rows|tostring)
end
EOF

cat << EOF > ${STYLESHEET}
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tcx="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">
	<xsl:output method="text" />
	<xsl:template match="/tcx:TrainingCenterDatabase/tcx:Activities/tcx:Activity">
		<xsl:if test="count(//tcx:LongitudeDegrees) > 0">
			<xsl:text>q=INSERT INTO laps (number, starttime, averageheartratebpm, maximumheartratebpm, calories, distancemeters, intensity, totaltimeseconds, the_geom) VALUES</xsl:text>
			<xsl:for-each select="tcx:Lap">
				<xsl:if test="//tcx:LongitudeDegrees">
					(	
						<xsl:value-of select="position()" />,
						TIMESTAMP '<xsl:value-of select="@StartTime" />',
						<xsl:value-of select="tcx:AverageHeartRateBpm/tcx:Value" />,
						<xsl:value-of select="tcx:MaximumHeartRateBpm/tcx:Value" />,
						<xsl:value-of select="tcx:Calories" />,
						<xsl:value-of select="tcx:DistanceMeters" />,
						'<xsl:value-of select="tcx:Intensity" />',
						<xsl:value-of select="tcx:TotalTimeSeconds" />,
						ST_SetSRID(ST_GeomFromText('MULTILINESTRING((<xsl:for-each select="tcx:Track/tcx:Trackpoint">
						<xsl:if test="tcx:Position/tcx:LongitudeDegrees">
							<xsl:value-of select="tcx:Position/tcx:LongitudeDegrees" /><xsl:text> </xsl:text>
							<xsl:value-of select="tcx:Position/tcx:LatitudeDegrees" />
							<xsl:if test="position() != last()">,</xsl:if>
						</xsl:if>
									</xsl:for-each>))'), 4326)
					)<xsl:if test="position() != last()">,</xsl:if>
				</xsl:if>
			</xsl:for-each>;
		</xsl:if>
	</xsl:template>
	<xsl:template match="text()"/>
</xsl:stylesheet>
EOF

FILES_BEFORE=$(ls -1 -d ${TCXDIR}/*.tcx)

echo "##### Starting download from Dropbox #####"
rclone sync drpbx:/Apps/tapiriik/ ${TCXDIR}

FILES_AFTER=$(ls -1 -d ${TCXDIR}/*.tcx)
FILES_NEW=$(comm -23 <(echo "${FILES_AFTER}") <(echo "${FILES_BEFORE}"))

echo
echo "##### Starting import to CartoCB / PostGIS #####"
echo "${FILES_NEW}" | while read FILE; do
	TEMPFILE=$(mktemp)
	
	xsltproc -o "${TEMPFILE}" "${STYLESHEET}" "${FILE}"

	printf "%s %-64s" "$(date +'%Y/%m/%d %H:%M:%S')" "$(basename "${FILE}"):"

	if [ -s ${TEMPFILE} ]; then
		curl -sSX POST --data @${TEMPFILE} ${CARTODB_EP} | jq -rf ${JQFILTER}
	else
		echo "Note: There are no trackpoints. Skipped"
	fi
done

rm ${STYLESHEET} ${JQFILTER}