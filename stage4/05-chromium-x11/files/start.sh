#!/usr/bin/bash

export CONFIG_MODE=0
export LAUNCH_URL=127.0.0.1
export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket
#export WINDOW_SIZE=
#export FLAGS=
#export CONTROL_TV=

# check GPU mem setting for Raspberry Pi
if [ "$(vcgencmd get_mem gpu | grep -o '[0-9]\+')" -lt 128 ]
  then
    echo -e "\033[91mWARNING: GPU MEMORY TOO LOW"
fi

sed -i -e 's/console/anybody/g' /etc/X11/Xwrapper.config
echo "needs_root_rights=yes" >> /etc/X11/Xwrapper.config
dpkg-reconfigure xserver-xorg-legacy

#Set whether to run Chromium in config mode or not
if [ ! -z ${CONFIG_MODE+x} ] && [ "$CONFIG_MODE" -eq "1" ]
  then
    export KIOSK=''
    echo "Enabling config mode"
    export CHROME_LAUNCH_URL="$LAUNCH_URL"
  else
   export KIOSK='--kiosk --start-fullscreen'
    echo "Disabling config mode"
    export CHROME_LAUNCH_URL="--app=$LAUNCH_URL"
fi

# if FLAGS env var is not set, use default 
if [[ -z ${FLAGS+x} ]]
  then
    echo "Using default chromium flags"
    export FLAGS=" $KIOSK --disable-dev-shm-usage --ignore-gpu-blacklist --enable-gpu-rasterization --force-gpu-rasterization --autoplay-policy=no-user-gesture-required --user-data-dir=/usr/src/app/settings --enable-features=WebRTC-H264WithOpenH264FFmpeg"
fi

# if no window size has been specified, find the framebuffer size and use that
if [[ -z ${WINDOW_SIZE+x} ]]
  then
    export WINDOW_SIZE=$( cat /sys/class/graphics/fb0/virtual_size )
    echo "Using fullscreen: $WINDOW_SIZE"
fi

# Start Tohora
cd /home/chromium/tohora && ./tohora 8080 /home/chromium/launch.sh &
# wait for it
sleep 3

if [ ! -z ${CONTROL_TV+x} ] && [ "$CONTROL_TV" -eq "1" ]
  then
    #Set the TV input to the Pi
    echo 'as' | cec-client -s -d 1
fi

if [[ ! -z ${LAUNCH_URL+x} ]]
  then
    sleep 5
    wget --post-data "url=$LAUNCH_URL" http://localhost:8080/launch/ >/dev/null 2>&1
fi


tail -f /dev/null

while : ; do echo "${MESSAGE=Idling...}"; sleep ${INTERVAL=600}; done