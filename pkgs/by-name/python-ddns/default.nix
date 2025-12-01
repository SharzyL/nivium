{ python3Packages, lib, srcs }:

python3Packages.buildPythonApplication {
  inherit (srcs.python-ddns) pname version src;

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  meta = {
    homepage = "https://github.com/NewFuture/DDNS";
    license = lib.licenses.mit;
  };
}

