#!/usr/bin/env bash
# Setup script for NixOS configuration with COSMIC Desktop

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}NixOS COSMIC Desktop Setup${NC}"
echo -e "==============================\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}This script needs to be run as root for some operations${NC}"
  echo -e "Please run with: ${GREEN}sudo $0${NC}\n"
  exit 1
fi

# Get the actual username (not root)
ACTUAL_USER=$(logname || echo "${SUDO_USER:-$USER}")
USER_HOME=$(eval echo ~$ACTUAL_USER)
CONFIG_DIR="$USER_HOME/.nixos"

echo -e "${BLUE}Step 1: Setting up flakes support${NC}"
mkdir -p /etc/nix
if ! grep -q "experimental-features" /etc/nix/nix.conf 2>/dev/null; then
  echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf
  echo -e "${GREEN}Enabled flakes in Nix configuration${NC}"
else
  echo -e "${YELLOW}Flakes already enabled in Nix configuration${NC}"
fi

# Get hostname
HOSTNAME=$(hostname)
echo -e "\n${BLUE}Step 2: Detecting system information${NC}"
echo -e "Hostname: ${GREEN}$HOSTNAME${NC}"
echo -e "User: ${GREEN}$ACTUAL_USER${NC}"

# Check if hardware-configuration.nix exists, and generate if not
if [ ! -f "$CONFIG_DIR/hosts/cosmic/hardware-configuration.nix" ]; then
  echo -e "\n${BLUE}Step 3: Generating hardware configuration${NC}"
  mkdir -p "$CONFIG_DIR/hosts/cosmic"
  nixos-generate-config --show-hardware-config > "$CONFIG_DIR/hosts/cosmic/hardware-configuration.nix"
  echo -e "${GREEN}Hardware configuration generated${NC}"
else
  echo -e "\n${YELLOW}Hardware configuration already exists${NC}"
fi

# Update hostname in configuration
echo -e "\n${BLUE}Step 4: Updating configuration with system information${NC}"
sed -i "s/hostname = \"cosmic-nixos\"/hostname = \"$HOSTNAME\"/" "$CONFIG_DIR/hosts/cosmic/configuration.nix"
sed -i "s/hostname/$HOSTNAME/g" "$CONFIG_DIR/flake.nix"
sed -i "s/myuser/$ACTUAL_USER/g" "$CONFIG_DIR/hosts/cosmic/configuration.nix"
sed -i "s/myuser/$ACTUAL_USER/g" "$CONFIG_DIR/hosts/cosmic/home.nix"
echo -e "${GREEN}Updated configuration files with hostname and username${NC}"

# Import hardware configuration
if ! grep -q "hardware-configuration.nix" "$CONFIG_DIR/hosts/cosmic/configuration.nix"; then
  sed -i "s|# Replace this comment with ./hardware-configuration.nix after install|./hardware-configuration.nix|" "$CONFIG_DIR/hosts/cosmic/configuration.nix"
  echo -e "${GREEN}Added hardware-configuration.nix import${NC}"
fi

# Set ownership to actual user
chown -R $ACTUAL_USER:$(id -gn $ACTUAL_USER) "$CONFIG_DIR"

echo -e "\n${BLUE}Step 5: Building and applying configuration${NC}"
echo -e "${YELLOW}This might take a while...${NC}"
nixos-rebuild switch --flake "$CONFIG_DIR#$HOSTNAME"

echo -e "\n${GREEN}Setup complete!${NC}"
echo -e "Your NixOS system with COSMIC Desktop is now configured."
echo -e "\nTo make changes in the future:"
echo -e "1. Edit files in ${BLUE}$CONFIG_DIR${NC}"
echo -e "2. Apply changes with: ${GREEN}sudo nixos-rebuild switch --flake $CONFIG_DIR#$HOSTNAME${NC}"
echo -e "\nFor Flatpak support, run: ${GREEN}flatpak remote-add --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo${NC}"
echo -e "\nEnjoy your COSMIC Desktop on NixOS!"