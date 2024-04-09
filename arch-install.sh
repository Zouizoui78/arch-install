#!/bin/bash

function numchoice
{
    if [ $# -ne 2 ]; then
        exit 1
    fi
    re='^[0-9]+$'
    if ! [[ $1 =~ $re ]] || ! [[ $2 =~ $re ]] ; then
        exit 1
    fi
    while [ -z $ask ] || ! [[ $ask =~ $re ]] || [ $ask -lt $1 ] || [ $ask -gt $2 ] ; do
        read ask
    done
    echo $ask
}

function yesno
{
    while [ -z $ask ] || ([ $ask != "y" ] && [ $ask != "n" ]); do
        read ask
    done
    echo $ask
}

# Enable multilib and color option
sed -i "s/#Color/Color/" /etc/pacman.conf
sed -i "s/#\[multilib\]/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist/" /etc/pacman.conf
sed -i "s/#Parallel/Parallel/" /etc/pacman.conf
pacman -Syu --noconfirm

# Use all available cores for makepkg compilation
sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j'`nproc`'"/' /etc/makepkg.conf

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc

# Activate en_DK.UTF-8 locale
# en_DK to have english with normal measurement units and formats for time, date, etc
echo "en_DK.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

echo "LANG=en_DK.UTF-8" > /etc/locale.conf

echo "Hostname ?"
read hostname
echo $hostname > /etc/hostname

echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts

echo "Root password ?"
passwd

echo "Select your CPU brand :
1- AMD
2- Intel"
cpu=$(numchoice 1 2)

echo "Did you install the linux-lts kernel ? y/n"
lts=$(yesno)

echo "Select a desktop environment :
1- Gnome
2- KDE"
de=$(numchoice 1 2)

# base (needed for a somewhat usable system)
packages="sudo dkms vim man-db man-pages texinfo"

# networking
packages="${packages} networkmanager openssh nmap nss-mdns wireguard-tools ethtool"

# audio
packages="${packages} pipewire lib32-pipewire pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack lib32-pipewire-jack"

# fonts
packages="${packages} noto-fonts noto-fonts-cjk noto-fonts-emoji"

# useful stuff
packages="${packages} git pyenv zip unrar unzip p7zip ncdu htop nvtop pacman-contrib firefox rsync wget vlc qbittorrent cups pinta libdbusmenu-glib reflector ntfs-3g screen"

# dev
packages="${packages} base-devel cmake"

if [ $lts = "y" ]; then
    packages="${packages} linux-lts-headers"
else
    packages="${packages} linux-headers"
fi

case $cpu in
    1) packages="${packages} amd-ucode";;
    2) packages="${packages} intel-ucode";;
esac

case $de in
    # gnome
    1) packages="${packages} baobab eog evince file-roller gdm gedit gnome-boxes gnome-calculator gnome-characters gnome-control-center gnome-disk-utility gnome-keyring seahorse gnome-logs dconf-editor gnome-menus gnome-remote-desktop gnome-screenshot gnome-session gnome-settings-daemon gnome-shell gnome-shell-extensions gnome-system-monitor gnome-terminal gnome-themes-extra gnome-user-docs gnome-video-effects gvfs gvfs-goa mutter nautilus networkmanager simple-scan tracker3 tracker3-miners xdg-user-dirs-gtk gnome-sound-recorder gnome-tweaks gnome-connections gnome-usage";;
    # kde
    2) packages="${packages} bluedevil breeze breeze-gtk drkonqi kde-gtk-config kdeplasma-addons kinfocenter kpipewire kscreen kscreenlocker kwallet-pam kwin plasma-desktop plasma-nm plasma-pa polkit-kde-agent print-manager sddm-kcm systemsettings xdg-desktop-portal-kde gwenview skanlite spectacle dolphin ark kcalc kwrite kfind konsole kwalletmanager";;
esac

pacman -S --needed $packages

# Give root commands access to sudo group
groupadd sudo
sed -i "s/# %sudo/%sudo/" /etc/sudoers

echo "Username ?"
read username
useradd -m $username --groups sudo,adm,ftp,games,http,log,rfkill,sys,audio,scanner,storage,video,input
echo "$username password ?"
passwd $username

# Install systemd-boot's efi boot manager
bootctl install

# Copy our systemd boot configuration
# It should automatically find existing Windows install
cp -r boot /

# Set ucode branc in boot config
case $cpu in
    1) sed -i "s/CPU_BRAND/amd/" /boot/loader/entries/arch.conf;;
    2) sed -i "s/CPU_BRAND/intel/" /boot/loader/entries/arch.conf;;
esac

# Set root UUID in boot config
root_uuid=$(findmnt --output=UUID --noheadings --target=/)
sed -i "s/ROOT_UUID/$root_uuid/" /boot/loader/entries/arch.conf

systemctl enable cups NetworkManager fstrim.timer avahi-daemon systemd-timesyncd bluetooth

# Set avahi conf
sed -i "s/hosts:.*/hosts: mymachines mdns_minimal \[NOTFOUND=return\] resolve \[!UNAVAIL=return\] files myhostname dns/" /etc/nsswitch.conf

case $de in
    1) systemctl enable gdm;;
    2) systemctl enable sddm;;
esac

echo "blacklist pcspkr" >> /etc/modprobe.d/blacklist.conf
case $cpu in
    1) echo "blacklist sp5100_tco" >> /etc/modprobe.d/blacklist.conf;;
    2) echo "blacklist iTCO_wdt" >> /etc/modprobe.d/blacklist.conf;;
esac

echo "kernel.sysrq=1 # Enable REISUB" > /etc/sysctl.d/99-sysctl.conf

if [ $de -eq 2 ]; then
echo "[General]
Numlock=on
" > /etc/sddm.conf
fi

cat bash.bashrc >> /etc/bash.bashrc
cp -r etc /
