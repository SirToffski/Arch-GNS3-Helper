#!/usr/bin/env bash

# This is a simple bash script to quickly install GNS3 server/gui on Arch Linux and Arch-based distros.

# AUR access and YAY are required.

source "$(find ~/*/Arch-GNS3-Helper/ -name colours.sh)"
my_separator="+----------------------------------------+"

latest_GNS3_release=v2.1.20

check_for_yay=$(pacman -Qe | grep -c yay)

if [[ "$check_for_yay" -lt 1 ]]; then
  echo -e "
  Yay does not appear to be installed.

  Would you like the script to install Yay pefore proceeding?

  1 = yes, 2 = no"

  read -r install_yay
  if [[ "$install_yay" == 1 ]]; then
    echo -e "
    $my_separator
    ${BCyan}Installing YAY${Color_Off}
    $my_separator"
    sleep 2
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
$my_separator
${IWhite}The script will perform installation steps as described in https://medium.com/@Ninja/install-gns3-on-arch-manjaro-linux-the-right-way-c5a3c4fa337d

You are encouraged to either read through the script or the article to make sure you understand the steps involved.${Color_Off}

$my_separator
"
read -n 1 -s -r -p "
Press any key to continue or CTRL+C to exit the script"

echo -e "
$my_separator
${BCyan}Installing dynamips${Color_Off}
$my_separator
"
sleep 2

sudo pacman -S libelf libpcap cmake --noconfirm
yay -S dynamips --noconfirm
sudo setcap cap_net_admin,cap_net_raw=ep "$(command -v dynamips)"

cd "$HOME" || exit
check_for_dynamips=$(dynamips 2> /dev/null | grep -c version)
if [[ "$check_for_dynamips" -lt 1 ]]; then
  echo -e "${On_Red}
  Unable to find dynamips after isntall....
  Aborting the script${Color_Off}"
  exit
fi

# Installing VPCS
echo -e "
$my_separator
${BCyan}Installing VPCS${Color_Off}
$my_separator
"
sleep 2
yay -S vpcs --noconfirm
cd "$HOME" || exit
check_for_vpcs=$(type vpcs | grep -c "vpcs is /usr/bin/vpcs")
if [[ "$check_for_vpcs" -lt 1 ]]; then
  echo -e "${On_Red}
  Unable to find VPCS after isntall....
  Aborting the script${Color_Off}"
  exit
fi

# Install IOUYAP
echo -e "
$my_separator
${BCyan}Installing IOUYAP${Color_Off}
$my_separator
"
sleep 2
sudo pacman -S iniparser --noconfirm
yay -S iouyap --noconfirm
cd "$HOME" || exit
sudo setcap cap_net_admin,cap_net_raw=ep "$(command -v iouyap)"
check_for_iouyap=$(iouyap -V | grep -c iouyap)
if [[ "$check_for_iouyap" -lt 1 ]]; then
  echo -e "${On_Red}
  Unable to find IOUYAP after install....
  Aborting the script${Color_Off}"
  exit
fi

# Install IOL Dependencies
echo -e "
$my_separator
${BCyan}Installing IOL Dependencies${Color_Off}
$my_separator
"
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
  echo -e "${On_Red}Excesscoll error prevention did not work....
  Something is not working correct..

  Ending the excipt${Color_Off}"
  exit
fi

# Install uBridge
sleep 2
echo -e "
$my_separator
${BCyan}Installing uBridge${Color_Off}
$my_separator
"
yay -S ubridge --noconfirm
cd "$HOME" || exit
check_for_ubridge=$(ubridge -v | grep -c ubridge)
if [[ "$check_for_ubridge" -lt 1 ]]; then
  echo -e "${On_Red}
  uBridge was not found after installation.
  Something did not work correctly.

  Edning the script....${Color_Off}"
  exit
fi

# Install QEMU
echo -e "
$my_separator
${BCyan}Installing QEMU${Color_Off}
$my_separator
"
sleep 2
sudo pacman -S qemu --noconfirm


# Install docker
echo -e "
$my_separator
${BCyan}Installing Docker${Color_Off}
$my_separator
"
sleep 2
sudo pacman -S docker --noconfirm
sudo systemctl enable docker.service
sudo systemctl start docker.service
sudo gpasswd -a "$USER" docker

# Install Wireshark
echo -e "
$my_separator
${BCyan}Installing Wireshark${Color_Off}
$my_separator
"
sleep 2
sudo pacman -S wireshark-qt --noconfirm
sudo gpasswd -a "$USER" wireshark

# Install python-pypi2pkgbuild
echo -e "
$my_separator
${BCyan}Installing python-pypi2pkgbuild${Color_Off}
$my_separator
"
sleep 2
yay -S python-pypi2pkgbuild --noconfirm
sudo pacman -S python-wheel --noconfirm
yay -S python-zipstream --noconfirm
# Install GNS3 Dependencies
echo -e "
$my_separator
${BCyan}Installing GNS3 Dependencies${Color_Off}
$my_separator
"
sleep 2
sudo pacman -S qt5-svg qt5-websockets python-pip python-pyqt5 python-sip --noconfirm
sudo pacman -S git --noconfirm

# Prepare to install GNS3-server
echo -e "
$my_separator
${BCyan}Prepare to install GNS3-server${Color_Off}
$my_separator
"
sleep 2
mkdir -p "$HOME"/GNS3-Dev && cd "$_" || exit
git clone https://github.com/GNS3/gns3-server.git
cd gns3-server || exit
git checkout "$latest_GNS3_release"
sudo pkgfile --update
echo -e "
$my_separator
${BCyan}Install GNS3-server${Color_Off}
$my_separator
"
sleep 2
PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f git+file://"$HOME"/GNS3-Dev/gns3-server
sleep 5
# Install GNS3 GUI
echo -e "
$my_separator
${BCyan}Install GNS3-GUI${Color_Off}
$my_separator
"
sleep 2
git clone https://github.com/GNS3/gns3-gui.git
cd gns3-gui || exit
git checkout "$latest_GNS3_release"
sudo pkgfile --update
PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f git+file://"$HOME"/GNS3-Dev/gns3-server/gns3-gui

# Verifying GNS3 installation
echo -e "
$my_separator
${BCyan}Verifying the installation.${Color_Off}
$my_separator
"
sleep 3
check_for_gns3=$(pacman -Qe | grep -c python-gns3)
if [[ "$check_for_gns3" -lt 2 ]]; then
  echo -e "${On_Red}
  It appears the installation was either completed partially or has not been completed at all....

  Checking further${Color_Off}"
  sleep 1
  check_for_gns3_gui=$(pacman -Qe | grep -c python-gns3-gui)
  if [[ "$check_for_gns3_gui" -lt 1 ]]; then
    echo -e "${On_Red}
    GNS 3 GUI was not installed...

    attempting to re-install${Color_Off}"
    PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f git+file://"$HOME"/GNS3-Dev/gns3-server/gns3-gui
    sleep 1
  fi
  check_for_gns3_server=$(pacman -Qe | grep -c python-gns3-server)
  if [[ "$check_for_gns3_server" -lt 1 ]]; then
    echo -e "${On_Red}
    GNS 3 Server was not installed...

      attempting to re-install${Color_Off}"
      PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f git+file://"$HOME"/GNS3-Dev/gns3-server
      sleep 1
  fi
else
  echo -e "${IGreen}
  Everything looks alright. If you are using Gnome or Budgie, the script can make a launcher icon for you.

  1 = yes, 2 = no${Color_Off}"
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
  echo -e "${IGreen}
  Installation has been completed!

  Please reboot your PC...${Color_Off}"
fi
