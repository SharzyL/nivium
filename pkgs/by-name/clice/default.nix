{ lib
, fetchFromGitHub
, stdenv
, cmake
, ninja
, libuv
, spdlog
, tomlplusplus
, flatbuffers
, croaring
}:

stdenv.mkDerivation rec {
  pname = "clice";
  version = "0.1.0-alpha.3";
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "clice-io";
    repo = "clice";
    rev = "v${version}";
    hash = "sha256-mMbTZfrm0vOH/6F6uf9k5fu8rvf096oE0IDJ3MKCR2g=";
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs = [
    libuv
    spdlog
    tomlplusplus
    flatbuffers
    croaring
  ];

  meta = {
    description = "A next-generation C++ language server for modern C++, focused on high performance and deep code intelligence";
    homepage = "https://github.com/clice-io/clice";
    license = lib.licenses.asl20;
    mainProgram = "clice";
  };
}
