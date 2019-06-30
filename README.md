= Arch GNS3 Helper Script

This repository contains a helper script based on one of my early blog posts about [installing GNS3 on Arch/Manjaro](https://medium.com/@Ninja/install-gns3-on-arch-manjaro-linux-the-right-way-c5a3c4fa337d).

== Purpose
The purpose of the script is to automate GNS3 installation on Arch Linux and Arch-based distros.

== Pre-requisites

A user with sudo privilidges. `git` needs to be installed to clone the repo. Most users will have git pre-installed with the system.

The `install-gns3.sh` script will automate most of the installation process.

== Features

=== Error checking

The script checks for errors along the way. If one of the steps did not succeed the script will be ended and the user notified.

Example:

[#src-listing]
[source,bash]
----
yay -S vpcs --noconfirm # <1>
cd "$HOME" || exit
check_for_vpcs=$(type vpcs | grep -c "vpcs is /usr/bin/vpcs") # <2>
if [[ "$check_for_vpcs" -lt 1 ]];  then # <3>
  echo -e "${On_Red}
  Unable to find VPCS after isntall....
  Aborting the script${Color_Off}"
  exit
fi
----
<1> Installing VPCS from AUR
<2> Define a variable to check for VPCS installation. If installed, grep value will be > 1. There are many ways to do this, I've chosed this way for no particular reason.
<3> If the value returned by the $check_for_vpcs is less then 1, notify the user and end the script.


== Usage

The script aims to provide a complete and functioning GNS3 experience. Using the script is simple. Recommended usage is to clone the repo and to execute the script via bash.

[#src-listing]
[source,bash]
----
git clone https://github.com/SirToffski/Arch-GNS3-Helper.git
cd Arch-GNS3-Helper/
bash install-gns3.sh
----

= Manual Installation

One could accomplish everything the script does via manual installation process outlined below.

== Enable AUR and Install YAY
==== Manjaro:

[#src-listing]
[source,bash]
----
$ sudo pacman -Syu
$ sudo pacman -S yay
----
==== Arch:
edit `/etc/pacman.conf`:

[#src-listing]
[source,bash]
----
$ sudo tee -a /etc/pacman.conf > /dev/null << EOL
> [archlinuxfr]
> SigLevel = Never
> Server = http://repo.archlinux.fr/$arch
> EOL
----

Now clone the YAY AUR repo and build the package - it will be installed after building:

[#src-listing]
[source,bash]
----
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
----


== Dependencies and all the necessary stuff
=== Dynamips
===== Install
[#src-listing]
[source,bash]
----
$ sudo pacman -S libelf libpcap cmake
$ yay -S dynamips --noconfirm
$ sudo setcap cap_net_admin,cap_net_raw=ep $(which dynamips)
----
===== Verify
[#src-listing]
[source,bash]
----
$ cd $HOME
$ dynamips 2> /dev/null | grep version
Cisco Router Simulation Platform (version 0.2.19-amd64/Linux stable)
$ getcap $(which dynamips)
/usr/bin/dynamips = cap_net_admin,cap_net_raw+ep
----
=== VPCS
===== Install
[#src-listing]
[source,bash]
----
$ yay -S vpcs --noconfrim
----
===== Verify
[#src-listing]
[source,bash]
----
$ cd $HOME
$ type vpcs
vpcs is /usr/bin/vpcs
$ vpcs -v | grep version
Welcome to Virtual PC Simulator, version 0.8 beta1
----
=== IOUYAP
===== Install
[#src-listing]
[source,bash]
----
$ sudo pacman -S iniparser
$ yay -S iouyap --noconfrim
$ cd $HOME
$ sudo setcap cap_net_admin,cap_net_raw=ep $(which iouyap)
----

===== Verify
[#src-listing]
[source,bash]
----
$ iouyap -V
iouyap version 0.97.0
$ getcap $(which iouyap)
/usr/bin/iouyap = cap_net_admin,cap_net_raw+ep
----

=== IOL (IOS on Linux)
> Due to obvious reasons, this guide will not provide information on where to get IOL, license, etc. Only the steps with required dependencies and configuration are provided for educational purposes only. Reader assumes all responsibility of researching and deciding whether to use IOL.

==== Dependencies

[#src-listing]
[source,bash]
----
$ sudo pacman -S lib32-openssl lib32-gcc-libs
$ sudo ln -s /usr/lib32/libcrypto.so.1.0.0 /usr/lib32/libcrypto.so.4
# Prevent EXCESSCOLL error
$ sudo sysctl net.unix.max_dgram_qlen=10000
# To make the above change persistent
$ sudo tee -a /etc/sysctl.d/99-sysctl.conf > /dev/null << EOL
> # Prevent EXCESSCOLL error for IOL
> net.unix.max_dgram_qlen=10000
> EOL
----

===== Verification
[#src-listing]
[source,bash]
----
$ sysctl net.unix.max_dgram_qlen
net.unix.max_dgram_qlen = 10000
$ tail -2 /etc/sysctl.d/99-sysctl.conf
# Prevent EXCESSCOLL error for IOL
net.unix.max_dgram_qlen=10000
----

=== uBridge
===== Installation
[#src-listing]
[source,bash]
----
$ yay -S ubridge --noconfirm
----
===== Verification
[#src-listing]
[source,bash]
----
$ cd $HOME
$ ubridge -v
ubridge version 0.9.14
$ getcap $(which ubridge)
/usr/local/bin/ubridge = cap_net_admin,cap_net_raw+ep
----

=== QEMU
[#src-listing]
[source,bash]
----
$ sudo pacman -S qemu
----
=== Docker
===== Installation
[#src-listing]
[source,bash]
----
$ sudo pacman -S docker
$ sudo systemctl enable docker.service
$ sudo systemctl start docker.service
$ sudo gpasswd -a $USER docker
# Log out and back in for the new group membership to take effect.
----
===== Verification
[#src-listing]
[source,bash]
----
$ sudo pacman -S docker
$ id -Gn
user wheel docker
$ docker info
----

=== Wireshark
===== Installation
[#src-listing]
[source,bash]
----
$ sudo pacman -S wireshark-qt
$ sudo gpasswd -a $USER wireshark
# Log out and back in for the new group membership to take effect.
----
===== Verification
[#src-listing]
[source,bash]
----
$ id -Gn
user wheel wireshark docker
----

=== GNS3
==== python-pypi2pkgbuild
Install python-pypi2pkgbuild from AUR to create PKGBUILD from GNS3 git repos
[#src-listing]
[source,bash]
----
$ yay -S python-pypi2pkgbuild --noconfirm
----
Create an alias for pypi2pkgbuild to make creating/installing PKGBUILD easier:
[#src-listing]
[source,bash]
----
$ alias pypi2pkgalias='PKGEXT=.pkg.tar pypi2pkgbuild.py -g cython -b /tmp/pypi2pkgbuild/ -f'
----
==== GNS3 dependencies:
[#src-listing]
[source,bash]
----
$ sudo pacman -S qt5-svg qt5-websockets python-pip python-pyqt5 python-sip python-wheel git
----
===== GNS3-Server
Clone the repository and checkout the latest stabe release. Build the package with pypi2pkgbuild.

[#src-listing]
[source,bash]
----
$ mkdir -p $HOME/GNS3-Dev && cd $_
$ git clone https://github.com/GNS3/gns3-server.git
$ cd gns3-server
$ git tag --list 'v2.1.*'
$ git checkout v2.1.20
$ pypi2pkgalias git+file://$PWD
$ cd ..
----

===== GNS3-GUI
Repeat the process with GNS3-GUI.

[#src-listing]
[source,bash]
----
$ git clone https://github.com/GNS3/gns3-gui.git
$ cd gns3-gui
$ git tag --list 'v2.1.*'
$ git checkout v2.1.20
$ pypi2pkgalias git+file://$PWD
----

===== Verification

[#src-listing]
[source,bash]
----
$ pacman -Qe | grep gns3
python-gns3-gui-git 2.1.12.r0.ga1496bff-1
python-gns3-server-git 2.1.12.r0.gbccdfc97-1
----

===== Gnome launcher
To create a Gnome launcher, the following may be used.

[#src-listing]
[source,bash]
----
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
----

= Changelog

June 29th 2019
* As usual, there were a ton of minor bugs in the initial commit. The script should now be completely functional. Some cosmetic changes will be added to make the script more readable.
