{ lib
, stdenv
, makeWrapper
, pulseaudio

, srcs
}:

stdenv.mkDerivation {
  inherit (srcs.i3-volume) pname version src;

  nativeBuildInputs = [
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild
    mkdir -p $out/bin
    cp volume $out/bin/volume
    wrapProgram $out/bin/volume --suffix PATH : ${lib.makeBinPath [ pulseaudio ]}
    runHook postBuild
  '';

  meta = with lib; {
    description = "Volume control and volume notifications";
    homepage = "https://github.com/hastinbe/i3-volume";
    license = licenses.gpl2Only;
  };
}
