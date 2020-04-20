#!/usr/bin/env bash

# This is a simple bash script to quickly install GNS3 server/gui on Arch Linux and Arch-based distros.

# AUR access and YAY are required.

my_repo_folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "$my_repo_folder"/docs/colours.sh

my_separator="+----------------------------------------+"

latest_GNS3_release=v2.2.7

yay_status_check() {
  check_for_yay=$(pacman -Qe | grep -c yay)

  if [[ $check_for_yay -lt 1 ]]; then
    printf %b\\n "
  Yay does not appear to be installed.

  Would you like the script to install Yay pefore proceeding?

  1 = yes, 2 = no"

    read -r install_yay
    if [[ $install_yay == 1 ]]; then
      printf %b\\n "
    $my_separator
    ${BCyan}Installing Yay${Color_Off}
    $my_separator"
      sleep 2
      git clone https://aur.archlinux.org/yay.git
      cd yay || exit
      makepkg -si
    else
      printf %b\\n "
    Yay is required for this script. Either install it manually then re-run the script, or let the script install it for you.

    Aborting the script...."
      exit
    fi
  fi
}

intro() {
  printf %b\\n "
$my_separator
${IWhite}The script will perform installation steps as described in https://medium.com/@Ninja/install-gns3-on-arch-manjaro-linux-the-right-way-c5a3c4fa337d

You are encouraged to either read through the script or the article to make sure you understand the steps involved.

Packets are only installed if not already present (--needed option).${Color_Off}

$my_separator\n"

  read -n 1 -s -r -p "
Press any key to continue or CTRL+C to exit the script"
}

install_dynamips() {
  # Install dynamips (Cisco router support)
  printf %b\\n "
$my_separator
${BCyan}Installing dynamips${Color_Off}
$my_separator
"
  sleep 2

  sudo pacman -S libelf libpcap cmake --noconfirm --needed
  yay -S dynamips --noconfirm --needed
  sudo setcap cap_net_admin,cap_net_raw=ep "$(command -v dynamips)"

  cd "$HOME" || exit
  check_for_dynamips=$(dynamips 2>/dev/null | grep -c version)
  if [[ $check_for_dynamips -lt 1 ]]; then
    printf %b\\n "${On_Red}
  Unable to find dynamips after install....
  Aborting the script${Color_Off}"
    exit
  fi
}

install_vpcs() {
  # Install VPCS
  printf %b\\n "
$my_separator
${BCyan}Installing VPCS${Color_Off}
$my_separator
"
  sleep 2

  yay -S vpcs --noconfirm --needed

  cd "$HOME" || exit
  if ! [[ -f "/usr/bin/vpcs" ]]; then
    printf %b\\n "${On_Red}
  Unable to find VPCS after install....
  Aborting the script${Color_Off}"
    exit
  fi
}

install_iouyap() {
  # Install IOUYAP
  printf %b\\n "
$my_separator
${BCyan}Installing IOUYAP${Color_Off}
$my_separator
"
  sleep 2
  sudo pacman -S iniparser --noconfirm --needed
  yay -S iouyap --noconfirm --needed
  cd "$HOME" || exit
  sudo setcap cap_net_admin,cap_net_raw=ep "$(command -v iouyap)"
  check_for_iouyap=$(iouyap -V | grep -c iouyap)
  if [[ $check_for_iouyap -lt 1 ]]; then
    printf %b\\n "${On_Red}
  Unable to find IOUYAP after install....
  Aborting the script${Color_Off}"
    exit
  fi
}

install_iol_dependencies() {
  # Install IOL Dependencies
  printf %b\\n "
$my_separator
${BCyan}Installing IOL Dependencies${Color_Off}
$my_separator
"
  sleep 2
  sudo pacman -S lib32-openssl lib32-gcc-libs --noconfirm --needed
  sudo ln -s /usr/lib32/libcrypto.so.1.0.0 /usr/lib32/libcrypto.so.4
  sudo sysctl net.unix.max_dgram_qlen=10000
  sudo tee -a /etc/sysctl.d/99-sysctl.conf >/dev/null <<EOL
# Prevent EXCESSCOLL error for IOL
net.unix.max_dgram_qlen=10000
EOL
  check_excesscoll_1=$(sysctl net.unix.max_dgram_qlen | grep -c 10000)
  check_excesscoll_2=$(tail -2 /etc/sysctl.d/99-sysctl.conf | grep -c 10000)

  if [[ $check_excesscoll_1 -lt 1 ]] || [[ $check_excesscoll_2 -lt 1 ]]; then
    printf %b\\n "${On_Red}EXCESSCOLL error prevention did not work....
  Something is not working correctly..

  Aborting the script${Color_Off}"
    exit
  fi
}

install_ubridge() {
  # Install uBridge
  sleep 2
  printf %b\\n "
$my_separator
${BCyan}Installing uBridge${Color_Off}
$my_separator
"
  yay -S ubridge --noconfirm --needed
  cd "$HOME" || exit
  check_for_ubridge=$(ubridge -v | grep -c ubridge)
  if [[ $check_for_ubridge -lt 1 ]]; then
    printf %b\\n "${On_Red}
  uBridge was not found after installation.
  Something did not work correctly.

  Aborting the script....${Color_Off}"
    exit
  fi
}

install_qemu() {
  # Install QEMU
  printf %b\\n "
$my_separator
${BCyan}Installing QEMU${Color_Off}
$my_separator
"
  sleep 2
  sudo pacman -S qemu qemu-arch-extra --noconfirm --needed
}

install_docker() {
  # Install docker
  printf %b\\n "
$my_separator
${BCyan}Installing Docker${Color_Off}
$my_separator
"
  sleep 2
  sudo pacman -S docker --noconfirm --needed
  sudo systemctl enable docker.service
  sudo systemctl start docker.service
  sudo gpasswd -a "$USER" docker
}

install_wireshark() {
  # Install Wireshark
  printf %b\\n "
$my_separator
${BCyan}Installing Wireshark${Color_Off}
$my_separator
"
  sleep 2
  sudo pacman -S wireshark-qt --noconfirm --needed
  sudo gpasswd -a "$USER" wireshark
}

install_python-pypi2pkgbuild() {
  # Install python-pypi2pkgbuild
  printf %b\\n "
$my_separator
${BCyan}Installing python-pypi2pkgbuild-git${Color_Off}
$my_separator
"
  sleep 2
  yay -S python-pypi2pkgbuild-git --noconfirm --needed
  sudo pacman -S python-wheel --noconfirm --needed
  yay -S python-zipstream --noconfirm --needed
}

install_gns_dependencies() {
  # Install GNS3 Dependencies
  printf %b\\n "
$my_separator
${BCyan}Installing GNS3 dependencies${Color_Off}
$my_separator
"
  sleep 2
  sudo pacman -S qt5-svg qt5-websockets python-pip python-pyqt5 python-sip --noconfirm --needed
  sudo pacman -S git --noconfirm --needed
}

install_gns3_server() {
  # Prepare to install GNS3-server
  printf %b\\n "
$my_separator
${BCyan}Preparing to install GNS3-server${Color_Off}
$my_separator
"
  sleep 2
  mkdir -p "$HOME"/GNS3-Dev && cd "$_" || exit
  git clone https://github.com/GNS3/gns3-server.git
  cd gns3-server || exit
  git checkout "$latest_GNS3_release"
  sudo pkgfile --update
  printf %b\\n "
$my_separator
${BCyan}Installing GNS3-server${Color_Off}
$my_separator
"
  sleep 2
  PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f git+file://"$HOME"/GNS3-Dev/gns3-server
  sleep 2
}

install_gns3_gui() {
  # Install GNS3 GUI
  printf %b\\n "
$my_separator
${BCyan}Installing GNS3-GUI${Color_Off}
$my_separator
"
  sleep 2
  git clone https://github.com/GNS3/gns3-gui.git
  cd gns3-gui || exit
  git checkout "$latest_GNS3_release"
  sudo pkgfile --update
  PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f git+file://"$HOME"/GNS3-Dev/gns3-server/gns3-gui
}

verify_gns3_installation() {
  # Verify GNS3 installation
  printf %b\\n "
$my_separator
${BCyan}Verifying the installation${Color_Off}
$my_separator
"
  sleep 3
  check_for_gns3=$(pacman -Qe | grep -c python-gns3)
  if [[ $check_for_gns3 -lt 2 ]]; then
    printf %b\\n "${On_Red}
  It appears the installation was either completed partially or has not been completed at all....

  Checking further${Color_Off}"
    sleep 1
    check_for_gns3_gui=$(pacman -Qe | grep -c python-gns3-gui)
    if [[ $check_for_gns3_gui -lt 1 ]]; then
      printf %b\\n "${On_Red}
    GNS3-GUI was not installed...

    attempting to re-install${Color_Off}"
      PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f git+file://"$HOME"/GNS3-Dev/gns3-server/gns3-gui
      sleep 1
    fi
    check_for_gns3_server=$(pacman -Qe | grep -c python-gns3-server)
    if [[ $check_for_gns3_server -lt 1 ]]; then
      printf %b\\n "${On_Red}
    GNS3-server was not installed...

      attempting to re-install${Color_Off}"
      PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f git+file://"$HOME"/GNS3-Dev/gns3-server
      sleep 1
    fi
  else
    printf %b\\n "${IGreen}
  Installation has been completed!

  Please reboot your PC or logout and in again for the changes to take effect.${Color_Off}"
  fi
}

main() {
  yay_status_check
  intro
  install_dynamips
  install_vpcs
  install_iouyap
  install_iol_dependencies
  install_ubridge
  install_qemu
  install_docker
  install_wireshark
  install_python-pypi2pkgbuild
  install_gns_dependencies
  install_gns3_server
  install_gns3_gui
  verify_gns3_installation
}

main
