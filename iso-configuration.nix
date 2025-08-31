{ config, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    ./configuration.nix
  ];

  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.volumeID = "CUSTOM-NIXOS";
  isoImage.storeContents = [
    config.system.build.toplevel
  ];

  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "nixos";
  environment.systemPackages = with pkgs; [
    (writeScriptBin "setup-encrypted-disk" ''
      #!/bin/sh
      lsblk
      read -p "Введите путь к диску (например, /dev/sdb): " DISK
      parted $DISK mklabel gpt
      parted $DISK mkpart primary ext4 0% 100%
      
      cryptsetup luksFormat $DISK"1"
      cryptsetup open $DISK"1" encrypted_disk
      mkfs.ext4 /dev/mapper/encrypted_disk
      tune2fs -O encrypt /dev/mapper/encrypted_disk
      
      echo "Диск подготовлен. Монтируйте: mount /dev/mapper/encrypted_disk /mnt"
    '')
  ];
}
