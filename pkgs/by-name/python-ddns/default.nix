{ python3Packages, lib, srcs }:

python3Packages.buildPythonApplication rec {
  inherit (srcs.python-ddns) pname version src;
  env.TRAVIS_TAG = version;
  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  meta = {
    homepage = "https://github.com/NewFuture/DDNS";
    license = lib.licenses.mit;
  };
}

