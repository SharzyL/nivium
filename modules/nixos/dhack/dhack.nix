{ stdenv
, fetchFromGitHub
, kernel
}:

stdenv.mkDerivation {
  pname = "dhack";
  version = "unstable-2022-10-17";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "dhack";
    rev = "2c09b3087c37c897d3b68db71cc230644617c7e3";
    hash = "sha256-86LahcWt0NXTRgSqmxR8nFJoPGOxSPO6wHWf5Ynvijg=";
  };

  makeFlags = kernel.makeFlags ++ [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];
  meta = {
    description = "Why the short keys";
    homepage = "https://github.com/NickCao/dhack";
  };
}
