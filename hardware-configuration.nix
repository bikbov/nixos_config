{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Поддержка различного оборудования
  boot.initrd.availableKernelModules = [ 
    "uhci_hcd" "ehci_pci" "xhci_pci" "usb_storage" "sd_mod" "sr_mod" 
    "ata_piix" "ahci" "nvme" "usbhid" "hid_generic"
  ];
  
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  
  # Файловые системы для Live USB
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  hardware.enableRedistributableFirmware = true;
}
