#!/bin/bash

# Exit Codes
# 1 : vobcopy failed
# 2 : encoding failed
# 3 : lock file present
# 4 : DVD not mounted
# 5 : VIDEO_TS not present - probably not a video DVD

VOB_DIR="/media/SERVER-FILES/vobs" # Location to store vobs
ENCODED_DIR="/media/SERVER-FILES/Movies" # Location to place encoded videos
DVD_DIR="/media/cdrom" # Mount location of dvd
DVD_DEV="/dev/cdrom" # DVD Device
LOCK_FILE="/tmp/ripdvd.lock" # Lock File
EMAIL="highland.brouwers@gmail.com" # Email address for notification
DVD_SUBJECT="DVD Rip & Encode" # Subject of dvd notification email
CD_SUBJECT="CD Rip & Import Complete" # Subject of cd notification email
MAILTEMP="/tmp/email"

# Only run if not already running
if [ -f "${LOCK_FILE}" ]; then
    echo "*** Lock file present"
    echo "\n\nRip failed (3).\nThere's already one decoding. What did you do...? Please try again later, or talk to Ethan when he gets back. :P" >>$MAILTEMP
    mail -s "$SUBJECT Failed (3)" "$EMAIL" < $MAILTEMP
    exit 3
fi

touch "${LOCK_FILE}"

mount | grep "${DVD_DIR}" || mount "${DVD_DEV}" "${DVD_DIR}"
if [ $? -ne 0 ]; then
    # dvd not mounted
    echo "*** DVD not mounted"
    rm "${LOCK_FILE}"
    umount "${DVD_DIR}" && eject "${DVD_DEV}"
    echo "\n\nRip failed (4).\nDVD did not mount properly. Please try again later, or talk to Ethan when he gets back. :P (The DVD player might be broken)" >>$MAILTEMP
    mail -s "$SUBJECT Failed (4)" "$EMAIL" < $MAILTEMP
    exit 4
fi

sleep 30;

if [ ! -d "${DVD_DIR}/VIDEO_TS" ]; then
    # not a video dvd?
    echo "*** VIDEO_TS directory not present"
    rm "${LOCK_FILE}"
    umount "${DVD_DIR}" && eject "${DVD_DEV}"
    echo "\n\nRip failed (5).\nDid you put a cd in...? This won't work yet with that." >>$MAILTEMP
    mail -s "$SUBJECT Failed (5)" "$EMAIL" < $MAILTEMP
    exit 5
fi


DVD_NAME="$(vobcopy -I 2>&1 > /dev/stdout | grep DVD-name | sed -e 's/.*DVD-name: //')"

# Don't need to copy all the vob's (hopefully...)
#vobcopy -m -o "${VOB_DIR}" -i "${DVD_DIR}"
#if [ $? -ne 0 ]; then
#   # vobcopy failed
#   echo "*** Error during vob copy"
#   rm -rf "${VOB_DIR}/${DVD_NAME}"
#   rm "${LOCK_FILE}"
#   exit 1
#fi

track=$(cd $VOB_DIR/$DVD_NAME/VIDEO_TS/ && du -hsx * | sort -rh | head -1 | cut -d ' ' -f 2 | cut -d '_' -f 2 | sed 's/^0*\([1-9]\)/\1/;s/^0*$/0/')

#HandBrakeCLI -i "${VOB_DIR}" -o "${ENCODED_DIR}/${DVD_NAME}.mp4" -m -e x264 --x264-preset medium --h264-profile high --h264-level 3.1 -q 20.0  -2 -T -X 1280 -Y 720 -a 1,1 -E copy:aac,copy:ac3 -B 265,265 -R Auto,Auto -D 0.0,0.0 --audio-fallback ffaac --loose-anamorphic --modulus 2 -t $track
HandBrakeCLI -i "${VOB_DIR}/${DVD_NAME}" -o "${ENCODED_DIR}/${DVD_NAME}.mp4" --preset="AppleTV 2" -t $track
if [ $? -ne 0 ]; then
    # encoding failed
    echo "*** Error during encoding"
    rm "${ENCODED_DIR}/${MP4_NAME}.mp4"
    rm "${LOCK_FILE}"
    umount "${DVD_DIR}" && eject "${DVD_DEV}"
    echo "\n\nRip of ${DVD_NAME} failed (2).\nEncoding failed. Please try again later, or talk to Ethan when he gets back. :P" >>$MAILTEMP
    mail -s "$SUBJECT Failed (2)" "$EMAIL" < $MAILTEMP
    exit 2
fi

umount "${DVD_DIR}" && eject "${DVD_DEV}"

rm "${LOCK_FILE}"

echo "\n\nRip of ${DVD_NAME} completed.\nEncoded to ${ENCODED_DIR}/${DVD_NAME}.mp4" >>$MAILTEMP

mail -s "$SUBJECT Completed!" "$EMAIL" < $MAILTEMP

rm -f $MAILTEMP
