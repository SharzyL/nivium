{ lib
, php
, python3
, makeWrapper

, srcs
}:

let
  pprp = python3.pkgs.buildPythonPackage {
    inherit (srcs.pprp) pname version src;
    pyproject = true;

    nativeBuildInputs = [ python3.pkgs.setuptools ];

    # nose is not supported in recent Python
    postPatch = ''
      substituteInPlace pprp/resources/requirements.txt \
        --replace "nose>=1.3.7" ""
    '';

    propagatedBuildInputs = with python3.pkgs; [
      # nose
      coverage
    ];

    pythonImportsCheck = [ "pprp" ];
  };

  eac_logchecker = python3.pkgs.buildPythonApplication {
    inherit (srcs.eac-logchecker) pname version src;
    pyproject = true;

    nativeBuildInputs = [ python3.pkgs.setuptools ];

    postPatch = ''
      substituteInPlace setup.py --replace 'pprp==0.2.6' 'pprp==0.2.7'
    '';

    propagatedBuildInputs = [ pprp ];

    pythonImportsCheck = [ "eac_logchecker" ];
  };
in

php.buildComposerProject (finalAttrs: {
  inherit (srcs.logchecker) pname version src;

  nativeBuildInputs = [ makeWrapper ];

  composerStrictValidation = false;

  vendorHash = "sha256-81hT5YQvdKmPrx6rSNaxmDKNL47ka5R/axUZepKdAf0=";

  passthru = { inherit eac_logchecker; };

  postInstall = ''
    wrapProgram $out/bin/logchecker --suffix PATH : ${lib.makeBinPath [ eac_logchecker ]} 
  '';

  meta = with lib; {
    description = "Logchecker for parsing and scoring logs coming from CD ripping programs";
    homepage = "https://github.com/OPSnet/Logchecker";
    license = licenses.unlicense;
    mainProgram = "logchecker";
    platforms = platforms.all;
  };
})
