{ pkgs ? import <nixpkgs> {} }:

with pkgs;
stdenvNoCC.mkDerivation {
  name = "claude-desktop-icon";
  version = "0.1.0";
  
  # We need the exe to extract proper icons, similar to how the Debian package does it
  src = fetchurl {
    url = "https://storage.googleapis.com/osprey-downloads-c02f6a0d-347c-492b-a752-3e0651722e97/nest-win-x64/Claude-Setup-x64.exe?v=0.9.3";
    hash = "sha256-uzRiNsvOUEVg+qZVJiRNGGUHpqGdGt7it/DFi7DHqCw=";
  };
  
  # Skip the default unpack phase since we'll handle it with 7z
  dontUnpack = true;
  
  nativeBuildInputs = [
    p7zip
    icoutils
    imagemagick
  ];
  
  buildPhase = ''
    # Extract the Claude Windows installer
    7z x -y $src
    
    # Find nupkg file (version number may change)
    NUPKG_FILE=$(find . -name "AnthropicClaude-*-full.nupkg" | head -1)
    if [ -z "$NUPKG_FILE" ]; then
      echo "Error: Could not find AnthropicClaude-*-full.nupkg file"
      exit 1
    fi
    
    # Extract the nupkg file
    7z x -y "$NUPKG_FILE"
    
    # Extract icons from the exe
    if [ -f "lib/net45/claude.exe" ]; then
      wrestool -x -t 14 "lib/net45/claude.exe" -o claude.ico
      icotool -x claude.ico
    else
      echo "Warning: Could not find claude.exe in expected location"
      exit 1
    fi
  '';
  
  installPhase = ''
    # Create directory structure
    mkdir -p $out/share/applications
    
    # Install icons in various sizes
    for size in 16 24 32 48 64 256; do
      # Find the icon file that matches the size
      ICON_FILE=$(find . -name "claude_*''${size}x''${size}x*.png" | head -1)
      if [ -n "$ICON_FILE" ]; then
        mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
        cp "$ICON_FILE" $out/share/icons/hicolor/''${size}x''${size}/apps/claude-desktop.png
      else
        echo "Warning: Missing ''${size}x''${size} icon"
      fi
    done
    
    # Create desktop entry with mimetype for x-scheme-handler/claude
    cat > $out/share/applications/claude-desktop.desktop << EOF
[Desktop Entry]
Name=Claude
GenericName=Claude Desktop
Comment=AI assistant from Anthropic
Exec=claude-desktop %u
Icon=claude-desktop
Terminal=false
Type=Application
Categories=Office;Utility;
MimeType=x-scheme-handler/claude;
EOF
  '';
  
  meta = with lib; {
    description = "Claude Desktop for Linux - Icons and desktop entry";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [];
  };
}