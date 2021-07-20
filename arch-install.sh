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

pacman -S vim --noconfirm

#Enable multilib and color option
vim /etc/pacman.conf
pacman -Syu --noconfirm

#Enable multicore for make compilation
vim /etc/makepkg.conf

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc

#Activate en_DK.UTF-8 locale
#en_DK to have english with normal measurement units and formats for time, date, etc
echo "en_DK.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

#en_DK : english with normal formats for everything
echo "LANG=en_DK.UTF-8" > /etc/locale.conf
# echo "KEYMAP=fr-latin1" > /etc/vconsole.conf

echo "Hostname ?"
read hostname
echo $hostname > /etc/hostname

echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts

echo "Root password"
passwd

echo "Select your CPU brand :
1- AMD
2- Intel"
cpu=$(numchoice 1 2)

echo "Did you install the linux-lts kernel ? y/n"
lts=$(yesno)

echo "Choose which desktop to install :
1- Gnome
2- KDE"
de=$(numchoice 1 2)

packages="dkms wpa_supplicant dhcpcd grub efibootmgr os-prober ntfs-3g openssh base-devel python git man-db man-pages texinfo ncdu htop nmap unrar unzip i7z nss-mdns pacman-contrib rsync wget inetutils vlc qbittorrent libreoffice-still libreoffice-still-fr cups noto-fonts-emoji pulseaudio pulseaudio-alsa discord pinta nvidia-utils lib32-nvidia-utils vulkan-icd-loader lib32-vulkan-icd-loader steam lutris wine wine-mono wine-gecko"

if [ $lts = "y" ]; then
    packages="${packages} linux-lts-headers nvidia-lts"
else
    packages="${packages} linux-headers nvidia"
fi

case $cpu in
    1) packages="${packages} amd-ucode";;
    2) packages="${packages} intel-ucode";;
esac

case $de in
    1) packages="${packages} baobab eog evince file-roller gdm gedit gnome-boxes gnome-calculator gnome-characters gnome-control-center gnome-disk-utility gnome-keyring gnome-logs gnome-menus gnome-remote-desktop gnome-screenshot gnome-session gnome-settings-daemon gnome-shell gnome-shell-extensions gnome-system-monitor gnome-terminal gnome-themes-extra gnome-user-docs gnome-video-effects gvfs gvfs-goa mutter nautilus networkmanager simple-scan tracker3 tracker3-miners xdg-user-dirs-gtk gnome-sound-recorder gnome-tweaks";;
    2) packages="${packages} xorg breeze breeze-gtk drkonqi kactivitymanagerd kde-cli-tools kde-gtk-config kdecoration kdeplasma-addons kgamma5 khotkeys kinfocenter kmenuedit kscreen kscreenlocker ksysguard kwallet-pam kwayland-integration kwayland-server kwin kwrited libkscreen libksysguard milou plasma-browser-integration plasma-desktop plasma-disks plasma-firewall plasma-integration plasma-nm plasma-pa plasma-systemmonitor plasma-workspace polkit-kde-agent powerdevil sddm-kcm systemsettings xdg-desktop-portal-kde skanlite ark dolphin gwenview kate kcalc kfind kompare konsole krdc krfb ksystemlog kwalletmanager okular partitionmanager spectacle kdialog yakuake sddm";;
esac

pacman -S --needed $packages

#Give root commands access to wheel group
vim /etc/sudoers

echo "Username ?"
read username
useradd -m $username --groups wheel,adm,ftp,games,http,log,rfkill,sys,audio,scanner,storage,video,input
echo "$username password"
passwd $username

#Change pgp server for one that is more reliable than the default one.
mkdir -p /home/${username}/.gnupg
chown -R ${username}:${username} /home/${username}/.gnupg
chmod -R u+rwX,g-rwx,o-rwx /home/${username}/.gnupg
echo "keyserver hkps://keyserver.ubuntu.com" >> /home/${username}/.gnupg/dirmngr.conf

grub-install --target=x86_64-efi --efi-directory=/EFI --bootloader-id=arch
#Set grub settings
vim /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable cups NetworkManager fstrim.timer avahi-daemon systemd-timesyncd

case $de in
    1) systemctl enable gdm;;
    2) systemctl enable sddm;;
esac

echo "blacklist pcspkr
blacklist iTCO_wdt
blacklist nouveau" >> /etc/modprobe.d/blacklist.conf

echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf

if [ $de -eq 2 ]; then
echo "[General]
Numlock=on

[X11]
ServerArguments=-dpi 96" > /etc/sddm.conf
fi

cat bash.bashrc >> /etc/bash.bashrc
cp vimrc /etc/vimrc