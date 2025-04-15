{ lib, stdenvNoCC, inter, opentype-feature-freezer }:

stdenvNoCC.mkDerivation {
  pname = "inter-ss03";

  inherit (inter) version src;

  nativeBuildInputs = [
    opentype-feature-freezer
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    for f in extras/ttf/*.ttf; do
      fname="$(basename "$f")"
      pyftfeatfreeze -f 'ss03' -S "$f" $out/share/fonts/truetype/"$fname"
    done

    runHook postInstall
  '';

  inherit (inter) meta;
}

