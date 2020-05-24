#!/usr/bin/env bash

# This is a simple bash script to quickly install GNS3 server/gui on Arch Linux and Arch-based distros.

# AUR access and YAY are required.

my_repo_folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "$my_repo_folder"/docs/colours.sh

my_separator="+----------------------------------------+"

latest_GNS3_release=2.2.8

yay_status_check() {

  if [[ -z $(which yay) ]]; then
    printf %b\\n "
  Yay does not appear to be installed.

  Would you like the script to install Yay pefore proceeding?

  1 = yes, 2 = no"

    read -r install_yay
    if [[ $install_yay == 1 ]]; then
      printf %b\\n "\n$my_separator\n${BCyan}Installing Yay${Color_Off}\n$my_separator"
      sleep 2
      git clone https://aur.archlinux.org/yay.git
      cd yay || exit
      makepkg -si
    else
      printf %b\\n "
    Yay is required for this script. \
    Either install it manually then re-run the script, \
    or let the script install it for you.\n
    Aborting the script...."
      exit
    fi
  fi
}

intro() {
  printf %b\\n "
$my_separator
${IWhite}The script will perform installation steps as described in
https://medium.com/@Ninja/install-gns3-on-arch-manjaro-linux-the-right-way-c5a3c4fa337d

You are encouraged to either read through the script or the article to
make sure you understand the steps involved.

Packages are only installed if not already present (--needed option).${Color_Off}

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
  yay -S dynamips --needed --answerclean "A" --noconfirm
  sudo setcap cap_net_admin,cap_net_raw=ep "$(command -v dynamips)"

  cd "$HOME" || exit
  if [[ -z $(which dynamips) ]]; then
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

  cd "$my_repo_folder"/pkg/vpcs || exit
  makepkg -sCf && sudo pacman -U vpcs-0.8beta1-1-x86_64.pkg.tar.xz --needed --noconfirm

  cd "$HOME" || exit
  if [[ -z $(which vpcs) ]]; then
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
  cd "$my_repo_folder"/pkg || exit
  sudo pacman -U iouyap-0.97-2-x86_64.pkg.tar.xz --needed --noconfirm
  cd "$HOME" || exit
  sudo setcap cap_net_admin,cap_net_raw=ep "$(command -v iouyap)"
  if [[ -z $(which iouyap) ]]; then
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
  yay -S ubridge --answerclean "A" --noconfirm --needed
  cd "$HOME" || exit
  if [[ -z $(which ubridge) ]]; then
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

install_pip2pkgbuild() {
  # Install python-pypi2pkgbuild
  printf %b\\n "
$my_separator
${BCyan}Installing pip2pkgbuild${Color_Off}
$my_separator
"
  sleep 2
  yay -S pip2pkgbuild --answerclean "A" --noconfirm --needed
  sudo pacman -S python-wheel --noconfirm --needed
  yay -S python-zipstream --answerclean "A" --noconfirm --needed
}

install_gns_dependencies() {
  # Install GNS3 Dependencies
  printf %b\\n "
$my_separator
${BCyan}Installing GNS3 dependencies${Color_Off}
$my_separator
"
  sleep 2
  sudo pacman -S qt5-svg qt5-websockets python-pip python-pyqt5 python-sip python-async_generator python-jinja python-distro python-jsonschema python-aiohttp-cors --noconfirm --needed
  sudo pacman -S git --noconfirm --needed

  mkdir -p "$HOME"/GNS3-Dev/python-requirements/{aiohttp,aiohttp-cors,aiofiles,psutil,async-timeout,py-cpuinfo,yarl} && cd "$HOME"/GNS3-Dev/python-requirements || exit

  cd "$HOME"/GNS3-Dev/python-requirements/aiohttp && pip2pkgbuild aiohttp -v 3.6.2 -n python-pip2pkg-aiohttp && makepkg -sCfi
  cd "$HOME"/GNS3-Dev/python-requirements/yarl && pip2pkgbuild yarl -v 1.3.0 -n python-pip2pkg-yarl && makepkg -sCfi
  cd "$HOME"/GNS3-Dev/python-requirements/aiofiles && pip2pkgbuild aiofiles -v 0.4.0 -n python-pip2pkg-aiofiles && makepkg -sCfi
  cd "$HOME"/GNS3-Dev/python-requirements/psutil && pip2pkgbuild psutil -v 5.6.6 -n python-pip2pkg-psutil && makepkg -sCfi
  cd "$HOME"/GNS3-Dev/python-requirements/async-timeout && pip2pkgbuild async-timeout -v 3.0.1 -n python-pip2pkg-async-timeout && makepkg -sCfi
  cd "$HOME"/GNS3-Dev/python-requirements/py-cpuinfo && pip2pkgbuild py-cpuinfo -v 5.0.0 -n python-pip2pkg-py-cpuinfo && makepkg -sCfi
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
  mkdir gns3-server && cd gns3-server || exit
  pip2pkgbuild gns3-server -v "$latest_GNS3_release" -n python-pip2pkg-gns3-server
  printf %b\\n "
$my_separator
${BCyan}Installing GNS3-server${Color_Off}
$my_separator
"
  sleep 2
  makepkg -sCfi
  sleep 2
}

install_gns3_gui() {
  # Install GNS3 GUI
  printf %b\\n "
$my_separator
${BCyan}Installing GNS3-GUI${Color_Off}
$my_separator
"
  cd "$HOME"/GNS3-Dev || exit
  mkdir gns3-gui && cd gns3-gui || exit
  pip2pkgbuild gns3-gui -v "$latest_GNS3_release" -n python-pip2pkg-gns3-gui
  sleep 2
  makepkg -sCfi
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
    if [[ -z $(which python-gns3-gui) ]]; then
      printf %b\\n "${On_Red}
    GNS3-GUI was not installed...

    attempting to re-install${Color_Off}"
      PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f git+file://"$HOME"/GNS3-Dev/gns3-server/gns3-gui
      sleep 1
    fi
    if [[ -z $(which python-gns3-server) ]]; then
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

create_gns3_launcher() {
  printf %b\\n "${IGreen}If you are using Gnome or Budgie, the script can make a launcher icon for you.
  1 = yes, 2 = no${Color_Off}"
    read -r make_launcher
    if [[ $make_launcher == 1 ]]; then
      sudo tee -a /usr/share/applications/gns3.desktop >/dev/null <<EOL
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
    printf %b\\n "${IGreen}
  Done! Please remember to reboot your PC.${Color_Off}"
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
  install_pip2pkgbuild
  install_gns_dependencies
  install_gns3_server
  install_gns3_gui
  verify_gns3_installation
  create_gns3_launcher
}

main
