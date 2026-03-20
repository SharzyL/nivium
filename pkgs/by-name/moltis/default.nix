{ zlib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  platform = "x86_64";
in
stdenv.mkDerivation rec {
  pname = "moltis";
  version = "0.10.18";

  src = fetchurl {
    url = "https://github.com/moltis-org/moltis/releases/download/v${version}/moltis-${version}-${platform}-unknown-linux-gnu.tar.gz";
    sha256 = "sha256-RlTkYwx0pDvW+KdmEUs7a1yKnupQEW4SMK0dnX0lpbk=";
  };

  sourceRoot = ".";

  buildInputs = [
    zlib
    stdenv.cc.cc
  ];

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    mkdir -p $out/{bin,share}
    cp moltis $out/bin/
    cp share -rT $out/share
  '';

  meta = {
    homepage = "https://github.com/moltis-org/moltis";
    platforms = [ "x86_64-linux" ];
  };
}
