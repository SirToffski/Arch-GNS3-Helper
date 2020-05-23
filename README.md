# Arch GNS3 Helper Script

This repository contains a helper script based on one of my early blog posts about [installing GNS3 on Arch/Manjaro](https://medium.com/@Ninja/install-gns3-on-arch-manjaro-linux-the-right-way-c5a3c4fa337d).

## Purpose
The purpose of the script is to automate GNS3 installation on Arch Linux and Arch-based distros.

## Pre-requisites

A user with sudo privilidges. `git` needs to be installed to clone the repo. Most users will have git pre-installed with the system.

The `install-gns3.sh` script will automate most of the installation process.

## Features

### Error checking

The script checks for errors along the way. If one of the steps did not succeed the script will be ended and the user notified.

Example:

```bash
yay -S vpcs --noconfirm # <1>
cd "$HOME" || exit
check_for_vpcs=$(type vpcs | grep -c "vpcs is /usr/bin/vpcs") # <2>
if [[ "$check_for_vpcs" -lt 1 ]];  then # <3>
  echo -e "${On_Red}
  Unable to find VPCS after isntall....
  Aborting the script${Color_Off}"
  exit
fi
```
1. Installing VPCS from AUR
2. Define a variable to check for VPCS installation. If installed, grep value will be > 1. There are many ways to do this, I've chosed this way for no particular reason.
3. If the value returned by the $check_for_vpcs is less then 1, notify the user and end the script.


## Usage

The script aims to provide a complete and functioning GNS3 experience. Using the script is simple. Recommended usage is to clone the repo and to execute the script via bash.

```bash
git clone https://github.com/SirToffski/Arch-GNS3-Helper.git
cd Arch-GNS3-Helper/
bash install-gns3.sh
```

# Manual Installation

One could accomplish everything the script does via manual installation process outlined below.

## Enable AUR and Install YAY
#### Manjaro:

```bash
$ sudo pacman -Syu
$ sudo pacman -S yay
```
#### Arch:
edit `/etc/pacman.conf`:

```bash
$ sudo tee -a /etc/pacman.conf > /dev/null << EOL
> [archlinuxfr]
> SigLevel = Never
> Server = http://repo.archlinux.fr/$arch
> EOL
```

Now clone the YAY AUR repo and build the package - it will be installed after building:

```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```


## Dependencies and all the necessary stuff
### Dynamips
##### Install
```bash
$ sudo pacman -S libelf libpcap cmake
$ yay -S dynamips --noconfirm
$ sudo setcap cap_net_admin,cap_net_raw=ep $(which dynamips)
```
##### Verify
```bash
$ cd $HOME
$ dynamips 2> /dev/null | grep version
Cisco Router Simulation Platform (version 0.2.19-amd64/Linux stable)
$ getcap $(which dynamips)
/usr/bin/dynamips = cap_net_admin,cap_net_raw+ep
```
### VPCS
##### Install
Recently VPCS no longer successfully builds from souce of Arch (at least with Kernel 5.6).
A workaround is to download the binary off the VPCS GitHub repository: https://github.com/GNS3/vpcs

Since we are using pacman for everything - we will first create a package using `makepkg`. Check out the vpcs folder in this repository for a PKGBUILD file.

If you are installing everything manually the easiest way is:

```bash
# Download the PKGBUILD file from this repo
$ mkdir vpcs && cd vpcs
$ wget https://raw.githubusercontent.com/SirToffski/Arch-GNS3-Helper/master/vpcs/PKGBUILD
$ makepkg -Ci
```
##### Verify
```bash
$ cd $HOME
$ which vpcs
/usr/bin/vpcs
$ vpcs -v | grep version
Welcome to Virtual PC Simulator, version 0.8 beta1
```
### IOUYAP
##### Install
```bash
$ sudo pacman -S iniparser
$ yay -S iouyap --noconfirm
$ cd $HOME
$ sudo setcap cap_net_admin,cap_net_raw=ep $(which iouyap)
```

##### Verify
```bash
$ iouyap -V
iouyap version 0.97.0
$ getcap $(which iouyap)
/usr/bin/iouyap = cap_net_admin,cap_net_raw+ep
```

### IOL (IOS on Linux)
> Due to obvious reasons, this guide will not provide information on where to get IOL, license, etc. Only the steps with required dependencies and configuration are provided for educational purposes only. Reader assumes all responsibility of researching and deciding whether to use IOL.

#### Dependencies

```bash
$ sudo pacman -S lib32-openssl lib32-gcc-libs
$ sudo ln -s /usr/lib32/libcrypto.so.1.0.0 /usr/lib32/libcrypto.so.4
# Prevent EXCESSCOLL error
$ sudo sysctl net.unix.max_dgram_qlen=10000
# To make the above change persistent
$ sudo tee -a /etc/sysctl.d/99-sysctl.conf > /dev/null << EOL
> # Prevent EXCESSCOLL error for IOL
> net.unix.max_dgram_qlen=10000
> EOL
```

##### Verification
```bash
$ sysctl net.unix.max_dgram_qlen
net.unix.max_dgram_qlen = 10000
$ tail -2 /etc/sysctl.d/99-sysctl.conf
# Prevent EXCESSCOLL error for IOL
net.unix.max_dgram_qlen=10000
```

### uBridge
##### Installation
```bash
$ yay -S ubridge --noconfirm
```
##### Verification
```bash
$ cd $HOME
$ ubridge -v
ubridge version 0.9.18
$ getcap $(which ubridge)
/usr/local/bin/ubridge = cap_net_admin,cap_net_raw+ep
```

### QEMU
```bash
$ sudo pacman -S qemu qemu-arch-extra
```
### Docker
##### Installation
```bash
$ sudo pacman -S docker
$ sudo systemctl enable docker.service
$ sudo systemctl start docker.service
$ sudo gpasswd -a $USER docker
# Log out and back in for the new group membership to take effect.
```
##### Verification
```bash
$ sudo pacman -S docker
$ id -Gn
user wheel docker
$ docker info
```

### Wireshark
##### Installation
```bash
$ sudo pacman -S wireshark-qt
$ sudo gpasswd -a $USER wireshark
# Log out and back in for the new group membership to take effect.
```
##### Verification
```bash
$ id -Gn
user wheel wireshark docker
```

### GNS3
#### python-pypi2pkgbuild-git
Install python-pypi2pkgbuild-git from AUR to create PKGBUILD from GNS3 git repos
```bash
$ yay -S python-pypi2pkgbuild-git --noconfirm
```
Create an alias for pypi2pkgbuild-git to make creating/installing PKGBUILD easier:
```bash
$ alias pypi2pkgalias='PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f'
```
#### GNS3 dependencies:
```bash
$ sudo pacman -S qt5-svg qt5-websockets python-pip python-pyqt5 python-sip python-wheel git
```
##### GNS3-Server
Clone the repository and checkout the latest stabe release. Build the package with pypi2pkgbuild.

```bash
$ mkdir -p $HOME/GNS3-Dev && cd $_
$ git clone https://github.com/GNS3/gns3-server.git
$ cd gns3-server
$ git tag --list 'v2.2.*'
$ git checkout v2.2.7
$ pypi2pkgalias git+file://$PWD
$ cd ..
```

##### GNS3-GUI
Repeat the process with GNS3-GUI.

```bash
$ git clone https://github.com/GNS3/gns3-gui.git
$ cd gns3-gui
$ git tag --list 'v2.2.*'
$ git checkout v2.2.7
$ pypi2pkgalias git+file://$PWD
```

##### Verification

```bash
$ pacman -Qe | grep gns3
python-gns3-gui-git 2.2.7.r0.gb1ec9d53-1
python-gns3-server-git 2.2.7.r0.g087cba39-1
```

##### Gnome launcher
To create a Gnome launcher, the following may be used.

```bash
$ sudo tee -a /usr/share/applications/gns3.desktop > /dev/null << EOL
> [Desktop Entry]
> Type=Application
> Encoding=UTF-8
> Name=GNS3
> GenericName=Graphical Network Simulator 3
> Comment=Graphical Network Simulator 3
> Exec=/usr/bin/gns3
> Icon=gns3
> Terminal=false
> Categories=Application;Network;Qt;
> EOL
```

# Changelog
June 29th 2019
* As usual, there were a ton of minor bugs in the initial commit. The script should now be completely functional. Some cosmetic changes will be added to make the script more readable.
