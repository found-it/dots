# SeriousShanns Nerd Font Mono (https://github.com/kaBeech/serious-shanns).
# Not in nixpkgs, so fetch the release assets directly.
# To update: bump `version` and refresh hashes with
#   nix-prefetch-url <url> | xargs nix hash convert --hash-algo sha256 --to sri
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "6.0.0";

  hashes = {
    Regular = "sha256-q+cFxNuQ7Lnec4BflfSiYUnkg+voEHqD/AIBFdW5Oy4=";
    Bold = "sha256-FiFPlPPKQTfiK86X75V+TCDcLwj4GgTbswRWrVE4Eyk=";
    Italic = "sha256-5mz024boiPl9NGfWa2NK7X94T3nxSsCBnQxI3KNc2Ig=";
    BoldItalic = "sha256-CqIOg/HiMlZ3MqW49BrxO0+uMCzmMdx+Lhj71quEjkE=";
    Light = "sha256-QgCuX/9rJYBA4+fnkn0J4IiMIm4bVRE4aSpXnIhrgHs=";
    LightItalic = "sha256-ltt3h3UHyJEC1VcQDlu/Afpgx8uaf+cZVPDODKPYvbM=";
  };

  fonts = lib.mapAttrsToList (
    style: hash:
    fetchurl {
      url = "https://github.com/kaBeech/serious-shanns/releases/download/v${version}/SeriousShannsNerdFontMono-${style}.otf";
      inherit hash;
    }
  ) hashes;
in
stdenvNoCC.mkDerivation {
  pname = "serious-shanns-nerd-font-mono";
  inherit version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/opentype
    for f in ${lib.concatStringsSep " " fonts}; do
      cp "$f" "$out/share/fonts/opentype/$(stripHash "$f")"
    done
    runHook postInstall
  '';

  meta = {
    description = "SeriousShanns: a Comic Shanns derivative, Nerd Font Mono variant";
    homepage = "https://github.com/kaBeech/serious-shanns";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
