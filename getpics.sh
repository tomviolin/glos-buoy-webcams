#!/bin/bash

LC_ALL=en_US.utf8
PAGER=more
PATH=/var/services/homes/glosbuoys/.local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin
PGDATA=/var/services/pgsql

DATE=`date "+%Y-%m-%d %H:%M:%S"`
YEAR=`date -d "$DATE" +%Y`
MONTH=`date -d "$DATE" +%m`
DAY=`date -d "$DATE" +%d`
HOUR=`date -d "$DATE" +%H`
MINUTE=`date -d "$DATE" +%M`
MINUTE="${MINUTE:0:1}0"

SMTPSERVER="smtp://129.89.7.85:25/" 
MOVIE_FORMAT=mp4

echo $YEAR-$MONTH-$DAY-$HOUR-$MINUTE
cd /var/services/homes/glosbuoys

IFS=,
echo "== START OF BUOY LOOP =="
mkdir /tmp/buoy_files_$$
BUOY_ATT=""
while read buoyname buoyaddr buoytz buoylat buoylong buoydesc buoyrtsp; do
	if [ "$buoyname" == "x" ]; then
		continue
	fi

	export TZ="$buoytz"
	thistz="$TZ"
	echo "NAME='$buoyname' ADDR='$buoyaddr'"
	DATE=`date "+%Y-%m-%d %H:%M:%S"`
	YEAR=`date -d "$DATE" +%Y`
	MONTH=`date -d "$DATE" +%m`
	DAY=`date -d "$DATE" +%d`
	HOUR=`date -d "$DATE" +%H`

	mkdir -p "$buoyname/$YEAR/$MONTH/$DAY"
	curl --connect-timeout 30 "http://$buoyaddr/image.jpg" > /tmp/getpics$$.jpg
	if [ -s /tmp/getpics$$.jpg ]; then
		exiftool /tmp/getpics$$.jpg -AllDates="$YEAR-$MONTH-$DAY $HOUR:$MINUTE"  -Comment="$buoydesc" -gpslatitude=$buoylat  -gpslongitude=$buoylong -gpslatituderef=N -gpslongituderef=W

		convert /tmp/getpics$$.jpg -gravity SouthEast -font ubuntu.ttf -pointsize 90 -stroke white -strokewidth 3 -annotate +8+0 "$MONTH-$DAY-$YEAR $HOUR:$MINUTE" -gravity NorthWest -draw 'image SrcOver 8,8 0,0 uwm_logo.png' "/tmp/${buoyname}_LATEST.jpg"
		cp "/tmp/${buoyname}_LATEST.jpg" "$buoyname/$YEAR/$MONTH/$DAY/$YEAR-$MONTH-$DAY-$HOUR-$MINUTE.jpg"
		cp /tmp/getpics$$.jpg "$buoyname/$YEAR/$MONTH/$DAY/noann-$buoyname-$YEAR-$MONTH-$DAY-$HOUR-$MINUTE.jpg"
	fi
	
	# SHIP OFF TO SHAREPOINT
	if [ -f /tmp/${buoyname}_LATEST.jpg ]; then
		BUOY_ATT="$BUOY_ATT -F \"attachment=@/tmpr/${buoyname}_LATEST.jpg\;encoder=base64\""
		docker run -v /tmp:/tmpr -t ubunturun curl --url $SMTPSERVER --mail-from 'GLOS-Buoy-Data-Group@uwm.edu' --mail-rcpt 'GLOS-Buoy-Data-Group@uwm.edu' -F '=Latest image from '"$buoyname"' ;type=text/plain' -F "attachment=@/tmpr/${buoyname}_LATEST.jpg;encoder=base64" -H "Subject: GLOS automated image update from $buoyname"
	fi

	if [ "$buoyrtsp" != "" ]; then
		docker run -t -v /tmp:/tmpr ubunturun ffmpeg -rtsp_transport tcp -i $buoyrtsp -frames 60 -s 960x540 -c:v h264 -preset veryslow -vf "drawtext=text='%{localtime\:%T}': fontcolor=white:fontsize=50:box=1:boxcolor=black@0.7: x=70: y=510" /tmpr/getpics$$.$MOVIE_FORMAT -y
		cp /tmp/getpics$$.$MOVIE_FORMAT /tmp/${buoyname}_LATEST.$MOVIE_FORMAT 
		# SHIP OFF TO SHAREPOINT
		if [ -f /tmp/${buoyname}_LATEST.$MOVIE_FORMAT ]; then
			BUOY_ATT="$BUOY_ATT -F attachment=@/tmpr/${buoyname}_LATEST.$MOVIE_FORMAT\;encoder=base64"
			docker run -t -v /tmp:/tmpr ubunturun curl --url $SMTPSERVER --mail-from 'GLOS-Buoy-Data-Group@uwm.edu' --mail-rcpt 'GLOS-Buoy-Data-Group@uwm.edu' -F "=Latest movie from ${buoyname} ;type=text/plain" -F "attachment=@/tmpr/${buoyname}_LATEST.$MOVIE_FORMAT;encoder=base64" -H "Subject: GLOS automated image update from $buoyname"
		fi
	fi

	if [ -f /tmp/getpics$$.jpg ]; then
		docker run -t -v /tmp:/tmpr ubunturun rm -f /tmpr/getpics$$.jpg
	fi
	if [ -f /tmp/getpics$$.$MOVIE_FORMAT ]; then
		docker run -t -v /tmp:/tmpr ubunturun rm -f /tmpr/getpics$$.$MOVIE_FORMAT
	fi
	export TZ="$thistz"
done < stations.csv
exit
