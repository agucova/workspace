# Slack CLI Package for NixOS

This package provides the Slack CLI for building Slack apps on NixOS and Darwin systems.

## Usage

The Slack CLI is automatically included in your development environment through the `modules/common/dev/default.nix` module.

After rebuilding your system, you can use:

```bash
# Authenticate with your Slack workspace
slack login

# Create a new Slack app
slack create my-app

# Run your app locally
slack run

# Deploy your app
slack deploy
```

## Updating the Package

To update to the latest version of Slack CLI:

```bash
cd ~/repos/workspace/nixos/packages/slack-cli
./update.sh
```

This will:
1. Fetch the latest version from Slack's API
2. Attempt to fetch the SHA256 hashes for each platform
3. Update the `default.nix` file

If the script can't fetch the hashes automatically, you'll need to:
1. Try to build the package: `nix build .#slack-cli`
2. Copy the correct hash from the error message
3. Replace `lib.fakeSha256` with the actual hash in `default.nix`

## Building and Testing

To build the package:

```bash
cd ~/repos/workspace/nixos

# Build for your current system
nix build .#slack-cli

# Test the binary
./result/bin/slack --version
```

## Supported Platforms

- `x86_64-linux` - Linux 64-bit
- `x86_64-darwin` - macOS Intel
- `aarch64-darwin` - macOS Apple Silicon

## Troubleshooting

### Hash Mismatch

If you see a hash mismatch error when building:

1. Copy the correct hash from the error message
2. Update the corresponding hash in `default.nix`
3. Rebuild

### Missing Dependencies on Linux

The package uses `autoPatchelfHook` to automatically patch the binary with the correct dynamic libraries. If you encounter missing library errors, you may need to add additional dependencies to the `nativeBuildInputs`.

## References

- [Slack CLI Documentation](https://api.slack.com/automation/cli)
- [Slack CLI Install Guide](https://api.slack.com/automation/cli/install)