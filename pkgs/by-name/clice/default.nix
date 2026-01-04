{ lib
, fetchFromGitHub
, runCommand
, gcc15Stdenv
, cmake
, ninja
, libuv
, spdlog
, tomlplusplus
, flatbuffers
, croaring
, llvmPackages
, python3
, cpptrace
, lld
}:

let
  stdenv = gcc15Stdenv;
  version = "unstable-2025-12-18";
  src = fetchFromGitHub {
    owner = "clice-io";
    repo = "clice";
    rev = "b8da7e79db199c3dca2502d082a42d8af0b55a9d";
    hash = "sha256-yTkp2QpNCrrhU9meiUnBJO7h/x2x5v0Tw/gwD2u0k6g=";
  };

  clice-llvm = runCommand (llvmPackages.llvm.name) { } ''
    cp ${llvmPackages.llvm.dev} -rT $out
    chmod -R +w $out
    cp ${llvmPackages.llvm.lib}/lib -rT $out/lib
    chmod -R +w $out
    cp ${llvmPackages.libclang.dev}/include -rT $out/include
    chmod -R +w $out
    cp ${llvmPackages.libclang.lib}/lib -rT $out/lib
    chmod -R +w $out

    mkdir -p $out/include/clang/Sema
    cp ${llvmPackages.llvm.monorepoSrc}/clang/lib/Sema/{CoroutineStmtBuilder.h,TypeLocBuilder.h,TreeTransform.h} \
      $out/include/clang/Sema

    mkdir -p $out/lib/clang
  '';

  libuv-cmake = stdenv.mkDerivation {
    inherit (libuv) pname version src buildInputs;
    nativeBuildInputs = [
      cmake
      ninja
    ];
  };

  clice-spdlog = spdlog.overrideAttrs (oldAttrs: {
    cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
      "-DSPDLOG_USE_STD_FORMAT=ON"
      "-DSPDLOG_NO_EXCEPTIONS=ON"
      "-DSPDLOG_FMT_EXTERNAL=OFF"
    ];
    doCheck = false;
  });

in
stdenv.mkDerivation {
  pname = "clice";
  strictDeps = true;
  inherit version src;

  nativeBuildInputs = [
    cmake
    ninja
    python3
    flatbuffers
    lld
  ];

  passthru = { inherit clice-llvm libuv-cmake cpptrace; };

  buildInputs = [
    clice-llvm
    libuv-cmake
    cpptrace
    clice-spdlog
    tomlplusplus
    croaring
    flatbuffers
  ];

  cmakeFlags = [
    "-DLLVM_INSTALL_PATH=${clice-llvm}"
  ];

  meta = {
    description = "A next-generation C++ language server for modern C++, focused on high performance and deep code intelligence";
    homepage = "https://github.com/clice-io/clice";
    license = lib.licenses.asl20;
    mainProgram = "clice";
  };
}
