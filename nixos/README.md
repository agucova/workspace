# NixOS & Darwin Configuration

Unified Nix Flake configuration for NixOS (Linux) and macOS (Darwin) using flake-parts.

## Directory Structure

```
nixos/
├── flake.nix           # Main entry point using flake-parts
├── install.sh          # NixOS installation script
├── lib/                # Shared library functions
├── modules/
│   ├── common/         # Cross-platform modules
│   │   ├── dev/        # Development tools
│   │   ├── security/   # 1Password integration
│   │   └── shell/      # Fish, starship, CLI tools
│   ├── darwin/         # macOS-specific
│   │   ├── apps/
│   │   └── system/
│   └── linux/          # Linux-specific
│       ├── desktop/
│       │   ├── apps/
│       │   ├── gnome/
│       │   ├── keybindings/  # macOS-like remapping
│       │   └── user/
│       ├── hardware/   # NVIDIA RTX 4090
│       ├── system/
│       │   ├── base/   # Core system
│       │   ├── disk/   # Disko BTRFS+LUKS
│       │   ├── hardening/
│       │   └── ssh/
│       └── vm/
├── packages/
└── systems/            # Host configurations
    ├── aarch64-darwin/
    │   └── hackbookv5/
    └── x86_64-linux/
        ├── hackstation/
        ├── server/
        └── vm/
```

## Essential Commands

### NixOS

```bash
# Apply configuration
sudo nixos-rebuild switch --flake .#hackstation --experimental-features 'nix-command flakes' --impure

# Build without applying
sudo nixos-rebuild build --flake .#hackstation --experimental-features 'nix-command flakes' --impure

# Update dependencies
nix flake update
nix flake lock --update-input nixpkgs  # Update specific input

# Using nh (better UX)
nh os switch
nh os switch --dry      # Preview changes
nh os switch --update   # Update and switch
```

### macOS

```bash
# First time setup
nix run nix-darwin -- switch --flake .#hackbookv5

# Subsequent rebuilds
nh darwin switch

# Update
nh darwin switch --update
```

### VM Testing

```bash
# Quick run (on x86_64 Linux)
nix run .#run-vm --impure

# Cross-architecture VM (x86_64 VM on ARM macOS)
nix run .#run-vm-cross --impure
# Note: Uses QEMU TCG emulation, 10-50x slower than native

# Build and run manually
nix build .#nixosConfigurations.vm.config.system.build.vm --impure
./result/bin/run-nixos-vm

# Test builds
nix build .#nixosConfigurations.hackstation.config.system.build.toplevel --impure --dry-run
nix build .#nixosConfigurations.server.config.system.build.toplevel --impure --dry-run
nix build .#nixosConfigurations.vm.config.system.build.toplevel --impure --dry-run
```

#### Cross-Architecture Support

The flake includes support for running x86_64 VMs on ARM hosts (like Apple Silicon Macs):

- **`run-vm`**: Native VM runner for x86_64 Linux hosts (uses KVM acceleration)
- **`run-vm-cross`**: Cross-architecture runner for ARM hosts (uses QEMU TCG emulation)

**Important**: Running x86_64 VMs on ARM requires a Linux builder since macOS cannot build Linux packages natively. The `run-vm-cross` script will guide you through setting up a builder if needed.

Setup options for Linux builders on macOS:
1. **Nix Darwin Linux VM builder** (recommended): `nix run nixpkgs#darwin.linux-builder`
2. **Remote builder**: Configure in `/etc/nix/nix.conf`
3. **Determinate Nix**: Comes with built-in Linux VM support

When running on ARM, the VM uses software emulation (TCG) which is 10-50x slower than native execution but functional for testing. The VM configuration uses `-cpu max` for better cross-architecture compatibility.

### Development

```bash
# Enter dev shell
nix develop

# Linting
statix check nixos/
statix fix nixos/           # Apply fixes
statix explain W20          # Explain warning

# Formatting
nixpkgs-fmt --check .

# Validation
nix flake check --no-build --impure

# Show flake outputs
nix flake show
nix flake metadata
```

## Bootstrapping from NixOS Live ISO

### Automated Installation

```bash
# 1. Boot from NixOS live media
# 2. Connect to internet (WiFi: nmcli device wifi connect "SSID" password "password")
# 3. Enable flakes and install git
export NIX_CONFIG="experimental-features = nix-command flakes"
nix-shell -p git

# 4. Clone repository
git clone https://github.com/agucova/workspace.git /tmp/workspace
cd /tmp/workspace/nixos

# 5. Run installation script
sudo ./install.sh
# Shows available disks and prompts for selection
# Or specify disk directly: sudo ./install.sh /dev/nvme1n1

# 6. Reboot
sudo reboot
```

The `install.sh` script handles:
- Internet connectivity check
- Disk verification
- BTRFS+LUKS partitioning via disko
- Hardware config generation
- NixOS installation with flake
- User password setup

### Manual Installation

```bash
# 1. Boot from NixOS live media and connect to internet
nmcli device wifi connect "SSID" password "password"

# 2. Enable flakes and clone repo
export NIX_CONFIG="experimental-features = nix-command flakes"
nix-shell -p git
git clone https://github.com/agucova/workspace.git /tmp/workspace
cd /tmp/workspace/nixos

# 3. Identify target disk
lsblk  # Find your disk (e.g., /dev/nvme1n1)

# 4. Partition with disko
# Edit disk path if needed
sudo vi ./modules/linux/system/disk/disko-config.nix
sudo nix run github:nix-community/disko -- --mode disko ./modules/linux/system/disk/disko-config.nix
# Enter LUKS password when prompted

# 5. Generate hardware config
sudo nixos-generate-config --no-filesystems --root /mnt

# 6. Install NixOS
sudo nixos-install --flake '.#hackstation' --impure
# Set root password when prompted

# 7. Set user password
sudo nixos-enter --root /mnt -c 'passwd agucova'

# 8. Reboot
sudo reboot
```

After reboot:
1. Enter LUKS password
2. Login with user password
3. Clone repo to permanent location

### Creating Bootable ISOs

```bash
# Build ISOs
nix build .#packages.x86_64-linux.iso-hackstation --impure
nix build .#packages.x86_64-linux.iso-vm --impure

# Write to USB (be careful with device selection!)
sudo dd if=./result/iso/nixos-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## Module Organization

### Common Modules (`modules/common/`)
- **dev**: Nix tools, Git, languages (Python/uv, Rust, Julia), Docker
- **security**: 1Password CLI, SSH agent, Git signing
- **shell**: Fish, starship, modern CLI tools (bat, ripgrep, fd, fzf)

### Linux Modules (`modules/linux/`)
- **desktop/gnome**: GNOME with minimal config
- **desktop/keybindings**: xremap for macOS-like shortcuts (`myMacosRemap.enable`)
- **desktop/apps**: 1Password, Claude Desktop
- **hardware**: NVIDIA drivers with Wayland
- **system/base**: AMD 7800X3D optimizations, PipeWire, zram
- **system/disk**: BTRFS+LUKS via disko
- **vm**: QEMU config with 12 cores, 8GB RAM

### Darwin Modules (`modules/darwin/`)
- **system**: Core packages, fonts, Touch ID sudo
- **apps**: Development apps, terminals

## Tips

```bash
# Toggle macOS keybindings in VM/Live ISO
toggle-macos-keybindings

# Check all systems before committing
for system in hackstation server vm; do
  echo "Checking $system..."
  nix build .#nixosConfigurations.$system.config.system.build.toplevel --impure --dry-run
done
```

## Notes

- `--impure` flag required for importing `/etc/nixos/hardware-configuration.nix`
- Home Manager integrated into system configs (no separate commands needed)
- Uses flake-parts for clean organization
- VM auto-detects CPU cores, includes same desktop setup as main system
