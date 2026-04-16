#!/bin/bash

# Exit on errors, print commands, ignore unset variables
set -ex +u

# change hostname
hostnamectl set-hostname photonvision

# silence log spam from dpkg
cat > /etc/apt/apt.conf.d/99dpkg.conf << EOF
Dpkg::Progress-Fancy "0";
APT::Color "0";
Dpkg::Use-Pty "0";
EOF

# run Photonvision install script
chmod +x ./install.sh
./install.sh --install-nm=yes --arch=aarch64 --version="$1"

# modify photonvision.service to enable big cores
# For reasons beyond human comprehension, the little cores are on 2, 3, 4, and 5.
sed -i 's/# AllowedCPUs=4-7/AllowedCPUs=0,1,6-11/g' /lib/systemd/system/photonvision.service
cp -f /lib/systemd/system/photonvision.service /etc/systemd/system/photonvision.service
chmod 644 /etc/systemd/system/photonvision.service
cat /etc/systemd/system/photonvision.service

# networkd isn't being used, this causes an unnecessary delay
systemctl disable systemd-networkd-wait-online.service

# PhotonVision server is managing the network, so it doesn't need to wait for online
systemctl disable NetworkManager-wait-online.service

# TODO: Disable bluetooth/wifi

rm -rf /var/lib/apt/lists/*
apt-get --yes -qq clean

rm -rf /usr/share/doc
rm -rf /usr/share/locale/
