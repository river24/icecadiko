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

wget -q -O "${TMP_DIR}/area.js" "http://radiko.jp/area"
AREA=`cat "${TMP_DIR}/area.js" | perl -pe 's!^.*span class="JP([0-9]{1,2})".*$!$1!g'`
TODOFUKEN=`cat "${TMP_DIR}/area.js" | perl -pe 's!^.*>(.*) JAPAN<.*$!$1!g'`

echo "Your IP is found in ${TODOFUKEN} by 'radiko.jp'."

wget -q -O "${TMP_DIR}/JP${AREA}.xml" "http://radiko.jp/v2/station/list/JP${AREA}.xml"
cat "${TMP_DIR}/JP${AREA}.xml" | grep "<feed>" | sort | uniq | sort | perl -pe 's!^.*/feed/(.*)\.xml.*$!$1!g' | while read STATION ; do echo "http://${ICECAST2_ADDR}:${APP_PORT}/${STATION}" > "${PLAYLIST_DIR}/${STATION}.m3u" ; done

while true; do
  read -p 'Do you want to scan all stations? (for radiko premium users) [y/N]: ' ANSWER
  case $ANSWER in
    [yY] | [yY][eE][sS] )
      AREA=1
      while [ "${AREA}" -le 47 ]
      do
        wget -q -O "${TMP_DIR}/JP${AREA}.xml" "http://radiko.jp/v2/station/list/JP${AREA}.xml"
        cat "${TMP_DIR}/JP${AREA}.xml" | grep "<feed>" | sort | uniq | sort | perl -pe 's!^.*/feed/(.*)\.xml.*$!$1!g' | while read STATION ; do echo "http://${ICECAST2_ADDR}:${APP_PORT}/${STATION}" > "${PLAYLIST_DIR}/${STATION}.m3u" ; done
        AREA=$(($AREA+1))
      done
      break;
      ;;
    "" | [nN] | [nN][oO] )
      break;
      ;;
    * )
      echo "Please answer y(yes) or n(no)."
  esac
done;

echo "Run: cp playlists/*.m3u /var/lib/mpd/playlists/"
echo "(You may need to use 'sudo')"

exit 0

