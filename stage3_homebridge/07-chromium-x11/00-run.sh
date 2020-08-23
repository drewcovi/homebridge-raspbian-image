# Install Golang
export GOLANG="$(curl https://golang.org/dl/|grep armv6l|grep -v beta|head -1|awk -F\> {'print $3'}|awk -F\< {'print $1'})"
wget https://golang.org/dl/$GOLANG
sudo tar -C /usr/local -xzf $GOLANG
rm $GOLANG
unset GOLANG

echo 'PATH=$PATH:/usr/local/go/bin
GOPATH=$HOME/golang' >> "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.profile"

source "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.profile"

# Build tohora
go get -d -v github.com/mozz100/tohora/...
cd "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/go/src/github.com/mozz100/tohora"
go build


# Add chromium user
useradd chromium -m -s /bin/bash -G root && \
    groupadd -r -f chromium && id -u chromium \
    && chown -R chromium:chromium /home/chromium

# Add tohora to chromium home
cp "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/go/src/github.com/mozz100/tohora" /home/chromium/tohora

usermod -a -G audio,video,tty chromium

install -m 644 \
    files/kiosk.service "${ROOTFS_DIR}/etc/systemd/system/"

install -v -o 1000 -g 1000 -m 755 \
    files/launch.sh "${ROOTFS_DIR}/home/chromium/"

install -v -o 1000 -g 1000 -m 644 \
    files/45-evdev.conf "${ROOTFS_DIR}/usr/share/X11/xorg.conf.d/"

# udev rule to set specific permissions 
install -v -o 1000 -g 1000 -m 644 \
    files/10-vchiq-permissions.rules "${ROOTFS_DIR}/etc/udev/rules.d/"

install -v -o chromium -g chromium -m 755 \
    files/xstart.sh "${ROOTFS_DIR}/home/chromium/"

install -v -o chromium -g chromium -m 755 \
    files/start.sh "${ROOTFS_DIR}/home/chromium/"

systemctl daemon-reload
systemctl enable kiosk