{ python3
, srcs
, lib
, stdenvNoCC
, makeWrapper
}:

let
  pythonEnv = python3.withPackages (ps: [ ps.requests ]);
in

stdenvNoCC.mkDerivation {
  inherit (srcs.pb) pname version src;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin $out/share/fish/vendor_completions.d $out/share/zsh/site-functions

    cp scripts/pb.fish $out/share/fish/vendor_completions.d
    cp scripts/_pb $out/share/zsh/site-functions
    cp scripts/pb $out/bin

    wrapProgram $out/bin/pb \
      --prefix PATH : ${lib.makeBinPath [ pythonEnv ]}
  '';
}
