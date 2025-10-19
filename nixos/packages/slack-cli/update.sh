#!/usr/bin/env bash
# Update script for Slack CLI package

set -euo pipefail

# Fetch the latest version from Slack's metadata
echo "Fetching latest Slack CLI version..."
VERSION=$(curl -s "https://api.slack.com/slackcli/metadata.json" | grep -o '"version": "[^"]*' | grep -o '[^"]*$' | head -1)

if [ -z "$VERSION" ]; then
    echo "Error: Could not fetch latest version"
    exit 1
fi

echo "Latest version: $VERSION"

# Function to fetch hash for a specific platform
fetch_hash() {
    local platform=$1
    local url=$2
    
    echo "Fetching hash for $platform..."
    local hash=$(nix-prefetch-url --unpack "$url" 2>/dev/null || echo "")
    
    if [ -z "$hash" ]; then
        echo "  Warning: Could not fetch hash for $platform"
        echo "  URL: $url"
        echo "  You'll need to build once to get the correct hash"
        echo "lib.fakeSha256"
    else
        echo "  Hash: $hash"
        # Convert to SRI hash format
        nix hash to-sri --type sha256 "$hash"
    fi
}

# Update the Nix file
echo ""
echo "Updating default.nix with version $VERSION..."

cat > default.nix <<EOF
{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
}:

let
  version = "$VERSION";
  
  sources = {
    x86_64-linux = {
      url = "https://downloads.slack-edge.com/slack-cli/slack_cli_\${version}_linux_64-bit.tar.gz";
      sha256 = $(fetch_hash "x86_64-linux" "https://downloads.slack-edge.com/slack-cli/slack_cli_${VERSION}_linux_64-bit.tar.gz");
    };
    x86_64-darwin = {
      url = "https://downloads.slack-edge.com/slack-cli/slack_cli_\${version}_macOS_amd64.tar.gz";
      sha256 = $(fetch_hash "x86_64-darwin" "https://downloads.slack-edge.com/slack-cli/slack_cli_${VERSION}_macOS_amd64.tar.gz");
    };
    aarch64-darwin = {
      url = "https://downloads.slack-edge.com/slack-cli/slack_cli_\${version}_macOS_arm64.tar.gz";
      sha256 = $(fetch_hash "aarch64-darwin" "https://downloads.slack-edge.com/slack-cli/slack_cli_${VERSION}_macOS_arm64.tar.gz");
    };
  };

  source = sources.\${stdenv.hostPlatform.system} or (throw "Unsupported platform: \${stdenv.hostPlatform.system}");

in stdenv.mkDerivation rec {
  pname = "slack-cli";
  inherit version;

  src = fetchurl {
    inherit (source) url sha256;
  };

  nativeBuildInputs = [ makeWrapper ] ++ lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p \$out/bin
    install -m755 bin/slack \$out/bin/slack

    runHook postInstall
  '';

  # The Slack CLI binary is dynamically linked on Linux
  # autoPatchelfHook will handle this automatically

  meta = with lib; {
    description = "Slack CLI for building Slack apps";
    homepage = "https://api.slack.com/automation/cli";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
    maintainers = [ ];
    mainProgram = "slack";
  };
}
EOF

echo ""
echo "Done! The package has been updated to version $VERSION"
echo ""
echo "To build and test:"
echo "  cd ~/repos/workspace/nixos"
echo "  nix build .#slack-cli"
echo ""
echo "If you see hash mismatch errors, replace the lib.fakeSha256 values with the correct hashes from the error messages."