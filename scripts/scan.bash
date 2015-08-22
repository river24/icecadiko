#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0);/bin/pwd)
PARENT_DIR=$(cd $(dirname $0);cd ..;/bin/pwd)

if [ -f "${SCRIPT_DIR}/config.bash" ]; then
  . "${SCRIPT_DIR}/config.bash"
else
  echo "'${SCRIPT_DIR}/config.bash' is not found."
  exit 1
fi

TMP_DIR="${SCRIPT_DIR}/../tmp"
PLAYLIST_DIR="${SCRIPT_DIR}/../playlists"

AREA=1

while [ "${AREA}" -le 47 ]
do
  wget -q -O "${TMP_DIR}/JP${AREA}.xml" "http://radiko.jp/v2/station/list/JP${AREA}.xml"
  cat "${TMP_DIR}/JP${AREA}.xml" | grep "<feed>" | sort | uniq | sort | perl -pe 's!^.*/feed/(.*)\.xml.*$!$1!g' | while read STATION ; do echo "http://${ICECAST2_ADDR}:${APP_PORT}/${STATION}" > "${PLAYLIST_DIR}/${STATION}.m3u" ; done
  AREA=$(($AREA+1))
done

echo "Run: sudo cp playlists/*.m3u /var/lib/mpd/playlists/"

exit 0

