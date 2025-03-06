#!/bin/bash

# === Configuration ===
DISK="/dev/sda"  # Change this if installing on another disk
HOSTNAME="arch"
USERNAME="siddhu"
PASSWORD="siddhu"

echo "==== Arch Linux Minimal + Openbox Installer ===="

# === Step 1: Partition the Disk ===
echo "== Partitioning Disk =="
parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB 513MiB  # 512MB EFI
parted -s $DISK set 1 boot on
parted -s $DISK mkpart primary linux-swap 513MiB 3.5GiB  # 3GB Swap
parted -s $DISK mkpart primary ext4 3.5GiB 100%  # Remaining Root Partition

# === Step 2: Format Partitions ===
echo "== Formatting Partitions =="
mkfs.fat -F32 ${DISK}1
mkswap ${DISK}2
mkfs.ext4 ${DISK}3

# === Step 3: Mount Partitions ===
echo "== Mounting Partitions =="
mount ${DISK}3 /mnt
mkdir -p /mnt/boot
mount ${DISK}1 /mnt/boot
swapon ${DISK}2

# === Step 4: Install Base System ===
echo "== Installing Base System =="
pacstrap /mnt base linux linux-firmware nano networkmanager

# === Step 5: Generate fstab ===
echo "== Generating fstab =="
genfstab -U /mnt >> /mnt/etc/fstab

# === Step 6: Configure System ===
arch-chroot /mnt /bin/bash <<EOF

echo "== Setting Timezone =="
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

echo "== Setting Locale =="
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "== Setting Hostname =="
echo "$HOSTNAME" > /etc/hostname

echo "== Enabling Networking =="
systemctl enable NetworkManager

echo "== Setting Root Password =="
echo root:$PASSWORD | chpasswd

echo "== Creating User =="
useradd -m -G wheel -s /bin/bash $USERNAME
echo $USERNAME:$PASSWORD | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

echo "== Installing Bootloader (GRUB) =="
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "== Installing Xorg, Openbox & Basic GUI Apps =="
pacman -S --noconfirm xorg openbox obconf obmenu nitrogen tint2 lightdm lightdm-gtk-greeter firefox lxterminal pcmanfm

echo "== Enabling LightDM =="
systemctl enable lightdm

echo "== Setting Up Openbox Config =="
mkdir -p /home/$USERNAME/.config/openbox
cp /etc/xdg/openbox/* /home/$USERNAME/.config/openbox
chown -R $USERNAME:$USERNAME /home/$USERNAME/.config

EOF

# === Step 7: Unmount and Reboot ===
echo "== Installation Complete! Unmounting and Rebooting =="
umount -R /mnt
reboot
