#!/bin/bash

# Exit Codes
# 1 : vobcopy failed
# 2 : encoding failed
# 3 : lock file present
# 4 : DVD not mounted
# 5 : VIDEO_TS not present - probably not a video DVD

VOB_DIR="/media/SERVER-FILES/dvdrip/vobs" # Location to store vobs
ATV2_DIR="/media/SERVER-FILES/Movies" # Location to place ATV2 encoded videos
DVD_DIR="/media/cdrom" # Mount location of dvd
DVD_DEV="/dev/cdrom" # DVD Device
LOCK_FILE="/media/SERVER-FILES/dvdrip/ripdvd.lock" # Lock File
EMAIL="highland.brouwers@gmail.com" # Email address for notification
DVD_SUBJECT="DVD Rip & Encode Complete" # Subject of dvd notification email
CD_SUBJECT="CD Rip & Import Complete" # Subject of cd notification email

# Only run if not already running
if [ -f "${LOCK_FILE}" ]; then
   echo "*** Lock file present"
   exit 3
fi

touch "${LOCK_FILE}"

mount | grep "${DVD_DIR}" || mount "${DVD_DEV}" "${DVD_DIR}"
if [ $? -ne 0 ]; then
   # dvd not mounted
   echo "*** DVD not mounted"
   rm "${LOCK_FILE}"
   exit 4
fi

sleep 30;

if [ ! -d "${DVD_DIR}/VIDEO_TS" ]; then
   # not a video dvd?
   echo "*** VIDEO_TS directory not present"
   rm "${LOCK_FILE}"
   exit 5
fi


DVD_NAME="$(vobcopy -I 2>&1 > /dev/stdout | grep DVD-name | sed -e 's/.*DVD-name: //')"

vobcopy -m -o "${VOB_DIR}" -i "${DVD_DIR}"
if [ $? -ne 0 ]; then
   # vobcopy failed
   echo "*** Error during vob copy"
   rm -rf "${VOB_DIR}/${DVD_NAME}"
   rm "${LOCK_FILE}"
   exit 1
fi


ATV2_NAME="${DVD_NAME}"
INC=""
while [ -f "${ATV2_DIR}/${ATV2_NAME}${INC}.mp4" ]; do ((INC=INC+1)); done;
if [ -n "${INC}" ]; then MP4_NAME="${ATV2_NAME}${INC}"; fi

HandBrakeCLI -i "${VOB_DIR}/${DVD_NAME}/" -o "${ATV2_DIR}/${ATV2_NAME}.mp4" --preset="AppleTV 2"
if [ $? -ne 0 ]; then
   # encoding failed
   echo "*** Error during encoding"
   rm -rf "${VOB_DIR}/${DVD_NAME}"
   rm "${ATV2_DIR}/${MP4_NAME}.mp4"
   rm "${LOCK_FILE}"
   exit 2
fi

#Comment out the following if you don't need to double encode

sleep 60;

IPAD_NAME="${DVD_NAME}"
INC=""
while [ -f "${IPAD_DIR}/${IPAD_NAME}${INC}.mp4" ]; do ((INC=INC+1)); done;
if [ -n "${INC}" ]; then MP4_NAME="${IPAD_NAME}${INC}"; fi

HandBrakeCLI -i "${VOB_DIR}/${DVD_NAME}/" -o "${IPAD_DIR}/${IPAD_NAME}.mp4" --preset="iPad"
if [ $? -ne 0 ]; then
        # encoding failed
        echo "*** Error during encoding"
        rm -rf "${VOB_DIR}/${DVD_NAME}"
        rm "${IPAD_DIR}/${MP4_NAME}.mp4"
        rm "${LOCK_FILE}"
        exit 2
fi

#Comment out above code if you don't need to double encode

rm -rf "${VOB_DIR}/${DVD_NAME}"

umount "${DVD_DIR}" && eject "${DVD_DEV}"

rm "${LOCK_FILE}"

echo "\n\nRip of ${DVD_NAME} completed.\nEncoded to ${ATV2_DIR}/${MP4_NAME}.mp4 and ${IPAD_DIR}/${MP4_NAME}.mp4" >>$MAILTEMP

mail -s "$SUBJECT" "$EMAIL" < $MAILTEMP

rm -f $MAILTEMP
