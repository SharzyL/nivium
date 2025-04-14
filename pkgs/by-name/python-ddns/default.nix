{ python3Packages, lib, srcs }:

python3Packages.buildPythonApplication rec {
  inherit (srcs.python-ddns) pname version src;
  env.TRAVIS_TAG = version;

  meta = {
    homepage = "https://github.com/NewFuture/DDNS";
    license = lib.licenses.mit;
  };
}

