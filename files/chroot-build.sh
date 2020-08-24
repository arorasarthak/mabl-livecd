#!/bin/bash

set -eu -o pipefail

echo >&2 ">>>>>> Initiating Package Setup "

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts

export HOME=/root
export LC_ALL=C

echo "xubuntu-fs-live" >/etc/hostname

# Cleanup and Update
# Remove unwanted stuff

apt-get update -y
apt-get upgrade -y
apt-get clean -y
apt-get autoremove -y

echo >&2 ">>>>>> Removing Software Packages "

apt-get purge -y -qq \
  transmission-gtk \
  transmission-common \
  gnome-mahjongg \
  gnome-mines \
  gnome-sudoku \
  libreoffice* \
  sgt-* \
  pidgin-* \
  simple-scan \
  xfburn \
  parole \
  ristretto \
  thunderbird thunderbird-* \
  gimp gimp-*

apt-get clean -y
apt-get autoremove -y
apt-get install git -y

# Begin ROS Noetic Installation
echo >&2 ">>>>>> Installing ROS Noetic "
apt-get update -y
sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
apt-get update -y
apt-get install ros-noetic-desktop-full -y
apt-get install python3-rosdep -y

# Baxter Stuff
mkdir -p /home/catkin_ws && git clone https://github.com/arorasarthak/baxter_ws.git /home/catkin_ws/.
rosdep init && rosdep update
add-apt-repository ppa:rock-core/qt4 -y
apt-get update -y
apt-get install qt4-default -y
cd /home/baxter_ws && rosdep install --from-paths src --ignore-src -r -y && cd -
cd /home/baxter_ws && catkin_make && cd -
echo "source /home/catkin_ws/devel/setup.bash" >> /etc/skel/.bashrc

# Gazebo Stuff
mkdir -p /home/gzweb
git clone -b gzweb_1.4.0-gazebo11 https://github.com/arorasarthak/gzweb.git /home/gzweb/.
apt-get install -y libjansson-dev nodejs npm nodejs libboost-dev imagemagick libtinyxml-dev mercurial cmake build-essential
cd /home/gzweb && git checkout gzweb_1.4.0-gazebo11 && source /usr/share/gazebo/setup.sh
npm run deploy --- -m local
cp -av /home/catkin_ws/baxter_description /home/gzweb/http/client/assets/.
cp -av /home/catkin_ws/rethink_ee_description /home/gzweb/http/client/assets/.
cd -

# V-REP Stuff goes here
echo >&2 ">>>>>> Installing Coppelia Sim/V-REP "
wget https://www.coppeliarobotics.com/files/CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz
tar -xvf CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz
mv CoppeliaSim_Edu_V4_1_0_Ubuntu20_04 /home/coppelia
cp -v /tmp/files/icons/logo.png /home/coppelia/helpFiles/.
rm -rf CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz

# Desktop Stuff
echo >&2 ">>>>>> Preparing Desktop "
mkdir -p /etc/skel/Desktop
cp -v /tmp/files/desktop/*.desktop /etc/skel/Desktop/.
chmod a+x /etc/skel/Desktop/*.desktop
cp -v /tmp/files/icons/roscore.png /usr/share/icons/.

# Conky Stuff
echo >&2 ">>>>>> Setting Up Cheatsheet "
apt-get install conky-all -y
cp -v /tmp/files/conky/cheatsheet.desktop /etc/xdg/autostart/.
mv /etc/conky/conky.conf /etc/conky/conky.conf.old
cp -v /tmp/files/conky/conky.conf /etc/conky/.

# VSCode Stuff
echo >&2 ">>>>>> Installing VSCode "
wget --output-document=vscode.deb https://go.microsoft.com/fwlink/?LinkID=760868
dpkg -i vscode.deb
rm -rf vscode.deb

# Cleanup
echo >&2 ">>>>>> Cleaning up and exiting from chroot "
apt-get clean -y
apt-get autoremove -y
truncate -s 0 /etc/machine-id
#rm /sbin/initctl
#dpkg-divert --rename --remove /sbin/initctl
apt-get clean
rm -rf /tmp/* ~/.bash_history
rm -rf /tmp/files

umount -lf /dev/pts
umount -lf /sys
umount -lf /proc

export HISTSIZE=0
