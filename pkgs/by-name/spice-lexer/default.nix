{ python3

, srcs
}:

python3.pkgs.buildPythonApplication {
  inherit (srcs.spiceForMinted) pname src;
  version = "unstable-${srcs.spiceForMinted.date}";
  pyproject = true;

  nativeBuildInputs = [
    python3.pkgs.setuptools
    python3.pkgs.wheel
  ];

  pythonImportsCheck = [ "spice" ];

  meta = {
    description = "Syntax highlight for the SPICE language using the minted Package for Latex";
    homepage = "https://github.com/salatielGarcia/spiceForMinted";
    # no license specified
  };
}
