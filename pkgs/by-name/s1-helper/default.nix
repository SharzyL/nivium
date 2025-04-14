{ stdenv
, lib
, python3
, runtimeShell

, srcs
}:

let
  py = python3.withPackages (ps: with ps; [ requests ]);
in
stdenv.mkDerivation {
  inherit (srcs.s1-helper) pname version src;

  patches = [ ./config-file.patch ];

  phases = [ "unpackPhase" "patchPhase" "installPhase" ];
  runner = ''
    #!${runtimeShell}
    exec ${py}/bin/python3 ${placeholder "out"}/lib/start.py "$@"
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/bin
    cp -r * $out/lib

    echo "$runner" >> $out/bin/s1-helper
    chmod +x $out/bin/s1-helper

    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/Fungx/Stage1stHelper";
    license = lib.licenses.mit;
  };
}
