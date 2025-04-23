# Minimal hardware configuration placeholder for bootstrapping/building.
# On the target machine, you'll typically merge settings detected by
# `nixos-generate-config --show-hardware-config` into this or a host-specific file.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ]; # Or "kvm-intel" - adjust if known, otherwise generic is fine
  boot.extraModulePackages = [ ];

  # Define a basic filesystem. Adapt if you know your target partitioning scheme.
  # This assumes a single root partition on /dev/sda1 using ext4.
  # You WILL need to adjust this after installing on real hardware based on
  # the output of `nixos-generate-config`.
  fileSystems."/" = {
     device = "/dev/disk/by-label/NIXOS_ROOT"; # Example label, adjust as needed
     fsType = "ext4";
  };

 fileSystems."/boot" = {
     device = "/dev/disk/by-label/NIXOS_BOOT"; # Example label, adjust as needed
     fsType = "vfat";
     options = [ "fmask=0077" "dmask=0077" ];
 };


  # Minimal swap - can be refined by zram/swapfile modules later
  swapDevices = [
     # { device = "/dev/disk/by-label/NIXOS_SWAP"; } # Example if using a swap partition
  ];

  # Enables DHCP on each ethernet and wireless interface. You may need to customize
  # this network configuration after installation, network interfaces are not detected here.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eth0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

  # Basic power management, often overridden by specific modules
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Set a reasonable default hardware platform profile
  hardware.platform = lib.mkDefault "generic";
}
