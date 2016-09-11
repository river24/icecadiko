#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export PATH=${PATH}

SCRIPT_DIR=$(cd $(dirname $0);/bin/pwd)
PARENT_DIR=$(cd $(dirname $0);cd ..;/bin/pwd)

if [ -f "${SCRIPT_DIR}/config.bash" ]; then
  . "${SCRIPT_DIR}/config.bash"
else
  echo "'${SCRIPT_DIR}/config.bash' is not found."
  exit 1
fi

PID=$$

LOGIN_URL="https://radiko.jp/ap/member/login/login"
CHECK_URL="https://radiko.jp/ap/member/webapi/member/login/check"
LOGOUT_URL="https://radiko.jp/ap/member/webapi/member/logout"
PLAYER_URL="http://radiko.jp/player/swf/player_4.1.0.00.swf"
AUTH1_URL="https://radiko.jp/v2/api/auth1_fms"
AUTH2_URL="https://radiko.jp/v2/api/auth2_fms"
CHANNEL_URL_PREFIX="http://radiko.jp/v2/station/stream/"

COOKIE_FILE="${TMP_DIR}/cookie.txt"
LOGIN_FILE="${TMP_DIR}/login.txt"
CHECK_FILE="${TMP_DIR}/check.txt"
LOGOUT_FILE="${TMP_DIR}/logout.txt"
PLAYER_FILE="${TMP_DIR}/player.swf"
KEY_FILE="${TMP_DIR}/authkey.png"
AUTH1_FILE="${TMP_DIR}/auth1_fms"
AUTH2_FILE="${TMP_DIR}/auth2_fms"
FLV_FILE="${TMP_DIR}/tmp.flv"

AUTHTOKEN_FILENAME="authtoken.bash"
AUTHTOKEN_FILE="${TMP_DIR}/${AUTHTOKEN_FILENAME}"

MODE="none"
CHANNEL=""

function Usage() {
  echo "usage : $0 play CHANNEL"
  echo "usage : $0 stop"
  echo "usage : $0 state"
  exit 1
}

function State() {
  ps x | grep -v grep | grep "vlc" | grep "${ICECAST2_PASS}@${ICECAST2_ADDR}:${ICECAST2_PORT}${ICECAST2_PATH}" | awk '{ print $1 }'
}

function Stop() {
  ps x | grep -v grep | grep "vlc" | grep "${ICECAST2_PASS}@${ICECAST2_ADDR}:${ICECAST2_PORT}${ICECAST2_PATH}" | awk '{ print $1 }' |
    while read TARGET_PID
    do
      if [ ${TARGET_PID} -ne ${PID} ]; then
        kill -KILL ${TARGET_PID}
      fi
    done
}

function Logout() {
   wget -q \
     --header="pragma: no-cache" \
     --header="Cache-Control: no-cache" \
     --header="Expires: Thu, 01 Jan 1970 00:00:00 GMT" \
     --header="Accept-Language: ja-jp" \
     --header="Accept-Encoding: gzip, deflate" \
     --header="Accept: application/json, text/javascript, */*; q=0.01" \
     --header="X-Requested-With: XMLHttpRequest" \
     --no-check-certificate \
     --load-cookies "${COOKIE_FILE}" \
     --save-headers \
     -O "${LOGOUT_FILE}" \
     "${LOGOUT_URL}"

    if [ -f "${COOKIE_FILE}" ]; then
        rm -f "${COOKIE_FILE}"
    fi
}

if [ $# -lt 1 ]; then
  Usage
fi

if [ $# -ge 1 ]; then
  MODE=$1
fi

if [ $# -ge 2 ]; then
  CHANNEL=$2
  CHANNEL_FILE="${TMP_DIR}/${CHANNEL}.xml"
fi

# validation
if [[ "${MODE}" =~ ^play$ ]]; then
  if [ -z "${CHANNEL}" ]; then
    Usage
  elif [ ! -e "${PARENT_DIR}/playlists/${CHANNEL}.m3u" ]; then
    echo "'${CHANNEL}' is not a valid channel."
    Usage
  fi
elif [[ "${MODE}" =~ ^(stop|state)$ ]]; then
  :
else
  Usage
fi

if [[ "${MODE}" =~ ^state$ ]]; then
  State
  exit 0
fi

if [[ "${MODE}" =~ ^stop$ ]]; then
  Stop
  exit 0
fi

if [[ "${MODE}" =~ ^play$ ]]; then
  if [[ "${CHANNEL}" =~ ^NHK ]]; then
    case $CHANNEL in
      "NHK1")
        RTMP_URL="rtmpe://netradio-r1-flash.nhk.jp"
        PLAY_PATH="NetRadio_R1_flash@63346"
        ;;
      "NHK2")
        RTMP_URL="rtmpe://netradio-r2-flash.nhk.jp"
        PLAY_PATH="NetRadio_R2_flash@63342"
        ;;
      "NHKFM")
        RTMP_URL="rtmpe://netradio-fm-flash.nhk.jp"
        PLAY_PATH="NetRadio_FM_flash@63343"
        ;;
      "NHK1_SENDAI")
        RTMP_URL="rtmpe://netradio-hkr1-flash.nhk.jp"
        PLAY_PATH="NetRadio_HKR1_flash@108442"
        ;;
      "NHKFM_SENDAI")
        RTMP_URL="rtmpe://netradio-hkfm-flash.nhk.jp"
        PLAY_PATH="NetRadio_HKFM_flash@108237"
        ;;
      "NHK1_NAGOYA")
        RTMP_URL="rtmpe://netradio-ckr1-flash.nhk.jp"
        PLAY_PATH="NetRadio_CKR1_flash@108234"
        ;;
      "NHKFM_NAGOYA")
        RTMP_URL="rtmpe://netradio-ckfm-flash.nhk.jp"
        PLAY_PATH="NetRadio_CKFM_flash@108235"
        ;;
      "NHK1_OSAKA")
        RTMP_URL="rtmpe://netradio-bkr1-flash.nhk.jp"
        PLAY_PATH="NetRadio_BKR1_flash@108232"
        ;;
      "NHKFM_NAGOYA")
        RTMP_URL="rtmpe://netradio-bkr1-flash.nhk.jp"
        PLAY_PATH="NetRadio_BKFM_flash@108233"
        ;;
      *)
        exit 1
    esac

    PLAYER_URL="http://www3.nhk.or.jp/netradio/files/swf/rtmpe.swf"

    rtmpdump --rtmp "${RTMP_URL}" \
             --playpath "${PLAY_PATH}" \
             --app "live" \
             --swfVfy "${PLAYER_URL}" \
             --live \
             -o - \
      | avconv -y \
               -i - \
               -vn \
               -acodec libmp3lame \
               -ab 128k \
               -f adts \
               /dev/stdout \
      | vlc -I dummy \
            /dev/stdin \
            vlc://quit \
            --sout "#std{access=shout,mux=raw,dst=source:${ICECAST2_PASS}@${ICECAST2_ADDR}:${ICECAST2_PORT}${ICECAST2_PATH}}" \
            --sout-shout-mp3 \
            --sout-shout-name="${CHANNEL} @ radiru" \
            --sout-shout-description="Restreaming of ${CHANNEL} @ radiru"
  else
    if [ -f "${FLV_FILE}" ]; then
      rm -f "${FLV_FILE}"
    fi
    touch "${FLV_FILE}"

    AUTHTOKEN_IS_VALID=0

    if [ -f "${CHANNEL_FILE}" ]; then
      rm -f "${CHANNEL_FILE}"
    fi

    wget -q -O "${CHANNEL_FILE}" "${CHANNEL_URL_PREFIX}${CHANNEL}.xml"

    stream_url=`echo "cat /url/item[1]/text()" | xmllint --shell "${CHANNEL_FILE}" | tail -2 | head -1`
    url_parts=(`echo ${stream_url} | perl -pe 's!^(.*)://(.*?)/(.*)/(.*?)$/!$1://$2 $3 $4!'`)

    rm -f "${CHANNEL_FILE}"

    if [ -f "${AUTHTOKEN_FILE}" ]; then
      . "${AUTHTOKEN_FILE}"

      rtmpdump -v \
               -r ${url_parts[0]} \
               --app ${url_parts[1]} \
               --playpath ${url_parts[2]} \
               -W ${PLAYER_URL} \
               -C S:"" -C S:"" -C S:"" -C S:${AUTHTOKEN} \
               --live \
               --stop 0.1 \
               --flv "${FLV_FILE}"

      if [ -s "${FLV_FILE}" ]; then
        echo "Authtoken is valid"
        AUTHTOKEN_IS_VALID=1
      else
        echo "Authtoken is expired"
        AUTHTOKEN_IS_VALID=0
      fi
    else
      echo "Authtoken is not found"
      AUTHTOKEN_IS_VALID=0
    fi

    if [ ${AUTHTOKEN_IS_VALID} -eq 0 ]; then
      if [ -f "${COOKIE_FILE}" ]; then
        Logout
      fi

      if [ ! -z ${RADIKO_MAIL} ]; then
        wget -q --save-cookie="${COOKIE_FILE}" \
             --keep-session-cookies \
             --post-data="mail=${RADIKO_MAIL}&pass=${RADIKO_PASS}" \
             -O "${LOGIN_FILE}" \
             "${LOGIN_URL}"

        if [ ! -f "${COOKIE_FILE}" ]; then
          echo "Failed to Login"
          exit 1
        fi

        wget -q \
             --header="pragma: no-cache" \
             --header="Cache-Control: no-cache" \
             --header="Expires: Thu, 01 Jan 1970 00:00:00 GMT" \
             --header="Accept-Language: ja-jp" \
             --header="Accept-Encoding: gzip, deflate" \
             --header="Accept: application/json, text/javascript, */*; q=0.01" \
             --header="X-Requested-With: XMLHttpRequest" \
             --no-check-certificate \
             --load-cookies "${COOKIE_FILE}" \
             --save-headers \
             -O "${CHECK_FILE}" \
             "${CHECK_URL}"

        if [ $? -ne 0 ]; then
          echo "Failed to Login"
          exit 1
        else
          echo "Succeeded to Login as '${RADIKO_MAIL}'"
        fi
      else
        echo "Continue as Anonymous User"
      fi

      if [ ! -f "${PLAYER_FILE}" ]; then
        wget -q -O "${PLAYER_FILE}" "${PLAYER_URL}"

        if [ $? -ne 0 ]; then
          echo "Failed to Get Player"
          Logout
          exit 1
        else
          echo "Succeeded to Get Player"
        fi
      fi

      if [ ! -f ${KEY_FILE} ]; then
        swfextract -b 14 ${PLAYER_FILE} -o ${KEY_FILE}

        if [ ! -f ${KEY_FILE} ]; then
          echo "Failed to Get Key Data"
          Logout
          exit 1
        else
          echo "Succeeded to Get Key Data"
        fi
      fi

      if [ -f "${AUTH1_FILE}" ]; then
        rm -f "${AUTH1_FILE}"
      fi

      wget -q \
           --header="pragma: no-cache" \
           --header="X-Radiko-App: pc_1" \
           --header="X-Radiko-App-Version: 2.0.1" \
           --header="X-Radiko-User: test-stream" \
           --header="X-Radiko-Device: pc" \
           --post-data='\r\n' \
           --no-check-certificate \
           --load-cookies ${COOKIE_FILE} \
           --save-headers \
           -O "${AUTH1_FILE}" \
           "${AUTH1_URL}"

      if [ $? -ne 0 ]; then
        echo "Failed in Auth1 Process"
        Logout
        exit 1
      else
        echo "Succeeded in Auth1 Process"
      fi

      authtoken=`perl -ne 'print $1 if(/x-radiko-authtoken: ([\w-]+)/i)' "${AUTH1_FILE}"`
      offset=`perl -ne 'print $1 if(/x-radiko-keyoffset: (\d+)/i)' "${AUTH1_FILE}"`
      length=`perl -ne 'print $1 if(/x-radiko-keylength: (\d+)/i)' "${AUTH1_FILE}"`
      partialkey=`dd if="${KEY_FILE}" bs=1 skip=${offset} count=${length} 2> /dev/null | base64`

      echo "AUTHTOKEN='${authtoken}'" > "${AUTHTOKEN_FILE}"
      # CURRENT_DATE=`date +%Y%m%d%H%M%S`
      # cp "${AUTHTOKEN_FILE}" "${AUTHTOKEN_FILE}_${CURRENT_DATE}"

      rm -f "${AUTH1_FILE}"

      if [ -f "${AUTH2_FILE}" ]; then
        rm -f "${AUTH2_FILE}"
      fi

      wget -q \
           --header="pragma: no-cache" \
           --header="X-Radiko-App: pc_1" \
           --header="X-Radiko-App-Version: 2.0.1" \
           --header="X-Radiko-User: test-stream" \
           --header="X-Radiko-Device: pc" \
           --header="X-Radiko-Authtoken: ${authtoken}" \
           --header="X-Radiko-Partialkey: ${partialkey}" \
           --post-data='\r\n' \
           --load-cookies ${COOKIE_FILE} \
           --no-check-certificate \
           -O "${AUTH2_FILE}" \
           "${AUTH2_URL}"

      if [ $? -ne 0 -o ! -f "${AUTH2_FILE}" ]; then
        echo "Failed in Auth2 Process"
        Logout
        exit 1
      else
        echo "Succeeded in Auth2 Process"
      fi

      areaid=`perl -ne 'print $1 if(/^([^,]+),/i)' "${AUTH2_FILE}"`
      echo "Area is ${areaid}"

      rm -f "${AUTH2_FILE}"
    fi

    if [ -f "${AUTHTOKEN_FILE}" ]; then
      . "${AUTHTOKEN_FILE}"
    fi

    rtmpdump -v \
             -r ${url_parts[0]} \
             --app ${url_parts[1]} \
             --playpath ${url_parts[2]} \
             -W ${PLAYER_URL} \
             -C S:"" -C S:"" -C S:"" -C S:${AUTHTOKEN} \
             --live \
             --flv - \
      | avconv -y \
               -i - \
               -vn \
               -acodec libmp3lame \
               -ab 128k \
               -f adts \
               /dev/stdout \
      | vlc -I dummy \
            /dev/stdin \
            vlc://quit \
            --sout "#std{access=shout,mux=raw,dst=source:${ICECAST2_PASS}@${ICECAST2_ADDR}:${ICECAST2_PORT}${ICECAST2_PATH}}" \
            --sout-shout-mp3 \
            --sout-shout-name="${CHANNEL} @ radiko" \
            --sout-shout-description="Restreaming of ${CHANNEL} @ radiko"
  fi
fi

