{ config, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    ./configuration.nix
  ];

  # Настройки для Live CD
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.volumeID = "CUSTOM-NIXOS";

  # Включить копирование store на ISO
  isoImage.storeContents = [
    config.system.build.toplevel
  ];

  # Автоматический вход
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "nixos";

  # Предустановленные скрипты для шифрования
  environment.systemPackages = with pkgs; [
    (writeScriptBin "setup-encrypted-disk" ''
      #!/bin/sh
      echo "Настройка шифрованного диска..."
      echo "Выберите диск для шифрования:"
      lsblk
      read -p "Введите путь к диску (например, /dev/sdb): " DISK
      
      # Создание разделов
      parted $DISK mklabel gpt
      parted $DISK mkpart primary ext4 0% 100%
      
      # Шифрование раздела
      cryptsetup luksFormat $DISK"1"
      cryptsetup open $DISK"1" encrypted_disk
      
      # Форматирование
      mkfs.ext4 /dev/mapper/encrypted_disk
      
      # Настройка fscrypt
      tune2fs -O encrypt /dev/mapper/encrypted_disk
      
      echo "Диск подготовлен. Монтируйте: mount /dev/mapper/encrypted_disk /mnt"
    '')
  ];
}