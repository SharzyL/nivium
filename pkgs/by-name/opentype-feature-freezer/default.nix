{ lib
, python3

, srcs
}:

python3.pkgs.buildPythonApplication {
  inherit (srcs.opentype-feature-freezer) pname version src;
  pyproject = true;

  postPatch = ''
    substituteInPlace pyproject.toml --replace "poetry.masonry.api" "poetry.core.masonry.api" --replace "\"poetry>=0.12\"," ""
  '';

  nativeBuildInputs = [
    python3.pkgs.configparser
    python3.pkgs.poetry-core
  ];

  propagatedBuildInputs = with python3.pkgs; [
    fonttools
  ];

  pythonImportsCheck = [ "opentype_feature_freezer" ];

  meta = with lib; {
    description = "Turns OpenType features 'on' by default in a font: reassigns the font's Unicode-to-glyph mapping fo permanently 'freeze' the 1-to-1 substitution features, and creates a new font";
    homepage = "https://pypi.org/project/opentype-feature-freezer/";
    license = licenses.asl20;
    mainProgram = "opentype-feature-freezer";
  };
}
