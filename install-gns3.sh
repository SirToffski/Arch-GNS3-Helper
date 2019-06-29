#!/usr/bin/env bash

# This is a simple bash script to quickly install GNS3 server/gui on Arch Linux and Arch-based distros.

# AUR access and YAY are required.

latest_GNS3_release=v2.1.21

check_for_yay=$(pacman -Qe | grep -c yay)

if [[ "$check_for_yay" -lt 1 ]]; then
  echo -e "
  Yay does not appear to be installed.

  Would you like the script to install Yay pefore proceeding?

  1 = yes, 2 = no"

  read -r install_yay
  if [[ "$install_yay" == 1 ]]; then
    echo -e "
    Installing YAY"
    sleep 1
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit
    makepkg -si
  else
    echo -e "
    YAY is required for this script. Either install it manually then re-run the script, or let the script install it for you.

    Ending the script...."
    exit
  fi
fi

echo -e "
The script will perform installation steps as described in https://medium.com/@Ninja/install-gns3-on-arch-manjaro-linux-the-right-way-c5a3c4fa337d

You are encouraged to either read through the script or the article to make sure you understand the steps involved."

read -n 1 -s -r -p "
Press any key to continue or CTRL+C to exit the script"

echo -e "
Installing dynamips"
sleep 2

sudo pacman -S libelf libpcap cmake --noconfirm
yay -S dynamips --noconfirm
sudo setcap cap_net_admin,cap_net_raw=ep "$(command -v dynamips)"

cd "$HOME" || exit
check_for_dynamips=$(dynamips 2> /dev/null | grep -c version)
if [[ "$check_for_dynamips" -lt 1 ]]; then
  echo -e "
  Unable to find dynamips after isntall....
  Aborting the script"
  exit
fi

# Installing VPCS
echo -e "Installing VPCS"
sleep 2
yay -S vpcs --noconfirm
cd "$HOME" || exit
check_for_vpcs=$(type vpcs | grep -c "vpcs is /usr/bin/vpcs")
if [[ "$check_for_vpcs" -lt 1 ]]; then
  echo -e "
  Unable to find VPCS after isntall....
  Aborting the script"
  exit
fi

# Install IOUYAP
echo -e "
Installing IOUYAP"
sleep 2
sudo pacman -S iniparser --noconfirm
yay -S iouyap --noconfirm
cd "$HOME" || exit
sudo setcap cap_net_admin,cap_net_raw=ep "$(command -v iouyap)"
check_for_iouyap=$(iouyap -V | grep -c iouyap)
if [[ "$check_for_iouyap" -lt 1 ]]; then
  echo -e "
  Unable to find IOUYAP after install....
  Aborting the script"
  exit
fi

# Install IOL Dependencies
echo -e "
Install IOL Dependencies"
sleep 2
sudo pacman -S lib32-openssl lib32-gcc-libs --noconfirm
sudo ln -s /usr/lib32/libcrypto.so.1.0.0 /usr/lib32/libcrypto.so.4
sudo sysctl net.unix.max_dgram_qlen=10000
sudo tee -a /etc/sysctl.d/99-sysctl.conf > /dev/null << EOL
# Prevent EXCESSCOLL error for IOL
net.unix.max_dgram_qlen=10000
EOL
check_excesscoll_1=$(sysctl net.unix.max_dgram_qlen | grep -c 10000)
check_excesscoll_2=$(tail -2 /etc/sysctl.d/99-sysctl.conf | grep -c 10000)

if [[ "$check_excesscoll_1" -lt 1 ]] || [[ "$check_excesscoll_2" -lt 1 ]] ; then
  echo -e "Excesscoll error prevention did not work....
  Something is not working correct..

  Ending the excipt"
  exit
fi

# Install uBridge
sleep 1
echo -e "
Install uBridge"
yay -S ubridge --noconfirm
cd "$HOME" || exit
check_for_ubridge=$(ubridge -v | grep -c ubridge)
if [[ "$check_for_ubridge" -lt 1 ]]; then
  echo -e "
  uBridge was not found after installation.
  Something did not work correctly.

  Edning the script...."
  exit
fi

# Install QEMU
echo -e "
Installing QEMU"
sleep 1
sudo pacman -S qemu --noconfirm


# Install docker
echo -e "
Installing Docker"
sleep 1
sudo pacman -S docker --noconfirm
sudo systemctl enable docker.service
sudo systemctl start docker.service
sudo gpasswd -a "$USER" docker

# Install Wireshark
echo -e "
Install Wireshark"
sleep 1
sudo pacman -S wireshark-qt --noconfirm
sudo gpasswd -a "$USER" wireshark

# Install python-pypi2pkgbuild
echo -e "
Install python-pypi2pkgbuild"
sleep 1
yay -S python-pypi2pkgbuild --noconfirm
alias pypi2pkgalias='PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f'

# Install GNS3 Dependencies
echo -e "
Install GNS3 Dependencies"
sleep 1
sudo pacman -S qt5-svg qt5-websockets python-pip python-pyqt5 python-sip --noconfirm
sudo pacman -S git --noconfirm

# Prepare to install GNS3-server
echo -e "
Prepare to install GNS3-server"
sleep 1
mkdir -p "$HOME"/GNS3-Dev && cd "$_" || exit
git clone https://github.com/GNS3/gns3-server.git
cd gns3-server || exit
git checkout "$latest_GNS3_release"
pypi2pkgalias git+file://"$PWD"
cd ..

# Install GNS3 GUI
echo -e "
Install GNS3 GUI"
sleep 1
git clone https://github.com/GNS3/gns3-gui.git
cd gns3-gui || exit
git checkout "$latest_GNS3_release"
pypi2pkgalias git+file://"$PWD"

# Verifying GNS3 installation
echo -e "
Verifying the installation"
check_for_gns3=$(pacman -Qe | grep -c python-gns3)
if [[ "$check_for_gns3" -lt 2 ]]; then
  echo -e "
  It appears the installation was either completed partially or has not been completed at all....

  Checking further"
  sleep 1
  check_for_gns3_gui=$(pacman -Qe | grep -c python-gns3-gui)
  if [[ "$check_for_gns3_gui" -lt 1 ]]; then
    echo -e "
    GNS 3 GUI was not installed..."
    sleep 1
  fi
  check_for_gns3_server=$(pacman -Qe | grep -c python-gns3-server)
  if [[ "$check_for_gns3_server" -lt 1 ]]; then
    echo -e "
    GNS 3 Server was not installed..."
    sleep 1
  fi
else
  echo -e "
  Everything looks alright. If you are using Gnome or Budgie, the script can make a launcher icon for you.

  1 = yes, 2 = no"
  read -r make_launcher
  if [[ "$make_launcher" == 1 ]]; then
    sudo tee -a /usr/share/applications/gns3.desktop > /dev/null << EOL
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=GNS3
GenericName=Graphical Network Simulator 3
Comment=Graphical Network Simulator 3
Exec=/usr/bin/gns3
Icon=gns3
Terminal=false
Categories=Application;Network;Qt;
EOL
  fi
  echo -e "
  Installation has been completed!

  Please reboot your PC..."
fi
