{ lib
, stdenv
, cmake
, fontconfig

, srcs
}:

stdenv.mkDerivation {
  inherit (srcs.libaribcaption) pname version src;

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    fontconfig
  ];

  meta = with lib; {
    description = "Portable ARIB STD-B24 Caption Decoder/Renderer";
    homepage = "https://github.com/xqq/libaribcaption";
    license = licenses.mit;
    mainProgram = "libaribcaption";
    platforms = platforms.all;
  };
}
