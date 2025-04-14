{ python3, lib, srcs }:

python3.pkgs.buildPythonApplication {
  inherit (srcs.music-tag) pname version src;
  doCheck = false;
  patches = [
    ./add-entry.patch
    ./no-sanitize-year.patch
    ./raw-proxy-default.patch
  ];
  propagatedBuildInputs = let ppkg = python3.pkgs; in [
    ppkg.mutagen
  ];
  meta = {
    homepage = "https://github.com/KristoforMaynard/music-tag";
    license = lib.licenses.mit;
  };
}

