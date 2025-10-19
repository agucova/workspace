{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
}:

let
  version = "3.6.1";
  
  sources = {
    x86_64-linux = {
      url = "https://downloads.slack-edge.com/slack-cli/slack_cli_${version}_linux_64-bit.tar.gz";
      sha256 = "sha256-flgKxKhnUNb6JvZrfYXYUKWDolXRnT7gUx4JwtEvNCE=";
    };
    x86_64-darwin = {
      url = "https://downloads.slack-edge.com/slack-cli/slack_cli_${version}_macOS_amd64.tar.gz";
      sha256 = "sha256-l2NMTSglNiVdFzhThVHToYF7FaC+ixMFIuX/jhCLfYQ=";
    };
    aarch64-darwin = {
      url = "https://downloads.slack-edge.com/slack-cli/slack_cli_${version}_macOS_arm64.tar.gz";
      sha256 = "sha256-/LxkWLShluSp9saUfB45mKq725IDjayozjTbAsmM6Bg=";
    };
  };

  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

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

    mkdir -p $out/bin
    install -m755 bin/slack $out/bin/slack-cli

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
    mainProgram = "slack-cli";
  };
}
