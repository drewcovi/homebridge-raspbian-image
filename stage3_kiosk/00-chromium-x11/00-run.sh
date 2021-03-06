#!/bin/bash -e 


#
# Install kiosk
#


install -m 644 files/kiosk.service "${ROOTFS_DIR}/etc/systemd/system/"

# install -v -d "${ROOTFS_DIR}/usr/local/share/kiosk"
# install -v -d "${ROOTFS_DIR}/usr/src/app/settings"
install -v -d "${ROOTFS_DIR}/usr/local/lib/kiosk/settings"
install -v -d "${ROOTFS_DIR}/root/go"

install -v -m 644 files/45-evdev.conf "${ROOTFS_DIR}/usr/share/X11/xorg.conf.d/"
# udev rule to set specific permissions 
install -v -m 644 files/10-vchiq-permissions.rules "${ROOTFS_DIR}/etc/udev/rules.d/"
install -v -m 755 files/xstart "${ROOTFS_DIR}/usr/local/lib/kiosk/"
install -v -m 755 files/launch "${ROOTFS_DIR}/usr/local/lib/kiosk/"
install -v -m 755 files/kiosk "${ROOTFS_DIR}/usr/local/sbin/"

export GOPATH="/root/go"
export GOROOT="/usr/local/go"
export GOLANG="$(curl -k https://golang.org/dl/|grep armv6l|grep -v beta|head -1|awk -F\> {'print $3'}|awk -F\< {'print $1'})"

on_chroot << EOF
set -x 

# Install Golang

if [ -z ${GOLANG+x} ]; then echo "GOLANG is unset"; else echo "var is set to '$GOLANG'"; fi
echo "GOLANG IS: ${GOLANG}"
wget "https://golang.org/dl/${GOLANG}"
sudo tar -C /usr/local -xzvf "${GOLANG}"
rm "${GOLANG}"
unset GOLANG

# Build tohora
/usr/local/go/bin/go get -d -v github.com/mozz100/tohora/...
cd "/root/go/src/github.com/mozz100/tohora"
/usr/local/go/bin/go build


# # Add chromium user
useradd chromium -m -s /bin/bash -G root && \
    groupadd -r -f chromium && id -u chromium \
    && chown -R chromium:chromium /home/chromium

# Move tohora to sbin
cp "/root/go/src/github.com/mozz100/tohora/tohora" /usr/local/sbin/
cp -r "/root/go/src/github.com/mozz100/tohora/templates" /usr/local/lib/kiosk/
rm -rf /root/go/src

usermod -a -G audio,video,tty chromium

chown -R chromium:chromium /usr/local/lib/kiosk

systemctl daemon-reload
systemctl enable kiosk
EOF
