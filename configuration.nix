{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ext4" "ntfs" "fat32" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "fscrypt" ];
  networking.networkmanager.enable = true;
  networking.hostName = "custom-nixos";
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "ru_RU.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  
  services.xserver.layout = "us,ru";
  services.xserver.xkbOptions = "grp:alt_shift_toggle";

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS Live User";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    initialPassword = "nixos";
  };

  environment.systemPackages = with pkgs; [
    # Основные инструменты
    git
    docker
    docker-compose
    rustc
    cargo
    rustfmt
    rust-analyzer
    lean4
    vscode
    google-chrome
    cryptsetup
    e2fsprogs
    dolphin
    konsole
    kate
    wget
    curl
    htop
    neofetch
    tree
    unzip
    zip
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;
  security.pam.enableFscrypt = true;
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "23.11";
}


environment.systemPackages = with pkgs; [
  (writeScriptBin "init-encrypted-storage" ''
    #!/usr/bin/env bash
    set -e
    echo "Доступные диски:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -v loop
    read -p "Введите устройство для шифрования (например, sdb): " DEVICE
    DISK="/dev/$DEVICE"
    
    if [ ! -b "$DISK" ]; then
        echo "Ошибка: $DISK не найден"
        exit 1
    fi
    
    echo "Внимание: все данные на $DISK будут удалены!"
    read -p "Продолжить? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo "Отменено"
        exit 0
    fi
    
    # Создание таблицы разделов
    echo "Создание таблицы разделов..."
    parted $DISK --script mklabel gpt
    parted $DISK --script mkpart primary ext4 0% 100%
    
    # LUKS шифрование
    echo "Настройка LUKS шифрования..."
    cryptsetup luksFormat $DISK"1"
    
    echo "Открытие зашифрованного раздела..."
    cryptsetup open $DISK"1" encrypted_storage
    
    # Форматирование с поддержкой fscrypt
    echo "Форматирование файловой системы..."
    mkfs.ext4 -F -O encrypt /dev/mapper/encrypted_storage
    
    mkdir -p /mnt/encrypted
    mount /dev/mapper/encrypted_storage /mnt/encrypted
    echo "Инициализация fscrypt..."
    fscrypt setup /mnt/encrypted
  '')
  
  (writeScriptBin "mount-encrypted-disk" ''
    #!/usr/bin/env bash   
    read -p "Введите устройство (например, sdb1): " DEVICE
    DISK="/dev/$DEVICE"
    
    if [ ! -b "$DISK" ]; then
        echo "Ошибка: $DISK не найден"
        exit 1
    fi
    
    cryptsetup open $DISK encrypted_storage
    mkdir -p /mnt/encrypted
    mount /dev/mapper/encrypted_storage /mnt/encrypted
  '')
];

boot.kernel.sysctl = {
  "vm.swappiness" = 1;
  "vm.dirty_ratio" = 5;
  "vm.dirty_background_ratio" = 2;
};

services.journald.extraConfig = ''
  Storage=volatile
  RuntimeMaxUse=30M
'';

boot.tmpOnTmpfs = true;



