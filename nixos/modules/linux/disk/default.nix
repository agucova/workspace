{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.myDisko;
in
{
  options.myDisko = {
    enable = lib.mkEnableOption "BTRFS with LUKS disk configuration using disko";
    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/nvme0n1";
      description = "The device to partition";
    };
    swapSize = lib.mkOption {
      type = lib.types.str;
      default = "16G";
      description = "Size of the swap file";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable LUKS autologin - automatically unlock encrypted root after initial boot
    boot.initrd.luks.devices."cryptroot" = {
      allowDiscards = true;
      bypassWorkqueues = true;
      # Enable FIDO2 hardware security key support
      fido2.credential = "auto";
      fido2.passwordLess = true;
    };

    # Enable disko
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = cfg.device;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                label = "boot";
                name = "ESP";
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "defaults"
                  ];
                };
              };
              luks = {
                size = "100%";
                label = "luks";
                content = {
                  type = "luks";
                  name = "cryptroot";
                  extraOpenArgs = [
                    "--allow-discards"
                    "--perf-no_read_workqueue"
                    "--perf-no_write_workqueue"
                  ];
                  # Hardware security module support
                  settings = {
                    crypttabExtraOpts = ["fido2-device=auto" "token-timeout=10"];
                  };
                  content = {
                    type = "btrfs";
                    extraArgs = ["-L" "nixos" "-f"];
                    subvolumes = {
                      "/root" = {
                        mountpoint = "/";
                        mountOptions = ["subvol=root" "compress=zstd" "noatime"];
                      };
                      "/home" = {
                        mountpoint = "/home";
                        mountOptions = ["subvol=home" "compress=zstd" "noatime"];
                      };
                      "/nix" = {
                        mountpoint = "/nix";
                        mountOptions = ["subvol=nix" "compress=zstd" "noatime"];
                      };
                      "/persist" = {
                        mountpoint = "/persist";
                        mountOptions = ["subvol=persist" "compress=zstd" "noatime"];
                      };
                      "/log" = {
                        mountpoint = "/var/log";
                        mountOptions = ["subvol=log" "compress=zstd" "noatime"];
                      };
                      "/swap" = {
                        mountpoint = "/swap";
                        swap.swapfile.size = cfg.swapSize;
                        swap.swapfile.priority = 10;
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

    # Mark some filesystems as needed for boot
    fileSystems."/persist".neededForBoot = true;
    fileSystems."/var/log".neededForBoot = true;

    # Configure hibernation support
    boot = {
      # This resume_offset value is for a 2TB drive, might need adjustment based on your hardware
      # Follow the Arch wiki to determine the correct value for your system:
      # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Acquire_swap_file_offset
      kernelParams = [
        "resume_offset=533760"
      ];
      resumeDevice = "/dev/disk/by-label/nixos";
    };

    # Hibernate settings
    # powerManagement.enable = true;
    # powerManagement.powertop.enable = true;

    # Install disko tools
    environment.systemPackages = with pkgs; [
      cryptsetup
      btrfs-progs
      disko
    ];
  };
}
