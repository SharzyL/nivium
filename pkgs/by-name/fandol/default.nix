{ lib, stdenv, fetchzip, unzip }:

let
  version = "0.3";
  pname = "fandol-${version}";
  src = fetchzip {
    url = "http://mirrors.ctan.org/fonts/fandol.zip";
    sha256 = "sha256-rvvsrB5NajDPT1QrsQWmyQnzyz30l1jc4KZogK8LNKU=";
  };

in
stdenv.mkDerivation {
  inherit pname version src;

  installPhase = ''
    mkdir -p $out/share/fonts/opentype
    cp *.otf $out/share/fonts/opentype
  '';

  meta = {
    homepage = "https://www.ctan.org/pkg/fandol";
    description = "Fandol fonts designed for Chinese typesetting";
    longDescription = ''
      Fandol fonts designed for Chinese typesetting. The current version contains four styles: Song, Hei, Kai, Fang.
      All fonts are in OpenType format.
    '';
    license = lib.licenses.gpl3;
    platforms = lib.platforms.all;
  };
}

