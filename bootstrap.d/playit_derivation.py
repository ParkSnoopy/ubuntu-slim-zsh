"""The architecture-pinned official Playit derivation."""

# Reference: https://github.com/mafen/playit-docker
PLAYIT_EXPRESSION = r"""
(let
  releases = {
    x86_64-linux = {
      arch = "amd64";
      sha256 = "e78d463d93aa1e3ec36a06ded5a1f4fe879905fdceb865df8f4cef6124f8a555";
    };
    aarch64-linux = {
      arch = "aarch64";
      sha256 = "cd3fa1cedac40a71d80a120e6353e08836308840340b58e659e8f25d00601f66";
    };
  };
  release = releases.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported Playit platform: ${pkgs.stdenv.hostPlatform.system}");
  version = "0.17.1";
in pkgs.runCommand "playit-${version}" {
  src = pkgs.fetchurl {
    url = "https://github.com/playit-cloud/playit-agent/releases/download/v${version}/playit-linux-${release.arch}";
    sha256 = release.sha256;
  };
} "install -Dm755 \"$src\" \"$out/bin/playit\"")
"""
