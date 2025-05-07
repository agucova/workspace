# VM runner script package
{ pkgs, lib, ... }:

pkgs.writeShellScriptBin "run-vm" ''
  #!/usr/bin/env bash
  set -euo pipefail

  # Get the system configuration name
  SYSTEM_NAME="vm"

  # Build the VM
  echo "Building VM for $SYSTEM_NAME..."
  VM_PATH=$(nix build ".#nixosConfigurations.$SYSTEM_NAME.config.system.build.vm" --no-link --print-out-paths --impure)

  # Run the VM script (named after the VM configuration)
  VM_SCRIPT="$VM_PATH/bin/run-$SYSTEM_NAME-vm"
  echo "Starting VM..."
  exec "$VM_SCRIPT" "$@"
''
