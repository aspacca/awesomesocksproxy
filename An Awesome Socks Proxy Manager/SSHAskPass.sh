#!/bin/sh
# askPass.sh
# iTunesAutoSync
#
# Created by Andrea Spacca on 04/04/10.
# Copyright 2010 Andrea Spacca. All rights reserved.
#!/bin/sh
CAPT=$*
FIFO="/tmp/`uuidgen`"
mkfifo "${FIFO}"

SCRIPT=`echo "tell application id \"org.spacca.SSH-Ask-Pass\" to «event sAkPdiag» \"${FIFO}\" given «class capt»:\"${CAPT}\""`

osascript -e "${SCRIPT}" > /dev/null 2>&1

cat "${FIFO}"

rm -f "${FIFO}"