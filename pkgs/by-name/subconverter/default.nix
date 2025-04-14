{ lib
, stdenv

, srcs
}:

stdenv.mkDerivation {
  inherit (srcs.subconverter) pname version src;

  buildCommand = ''
    mkdir -p $out/{bin,share}
    tar xzf "$src"
    mv subconverter/subconverter $out/bin
    mv subconverter/{base,config,rules} $out/share/
    mv subconverter/pref.example.ini $out/share/pref.ini
  '';

  meta = with lib; {
    description = "Utility to convert between various subscription format";
    homepage = "https://github.com/tindy2013/subconverter";
    license = licenses.gpl3Only;
    mainProgram = "subconverter";
    platforms = [ "x86_64-linux" ];
  };
}
