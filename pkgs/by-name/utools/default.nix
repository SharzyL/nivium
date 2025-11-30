{ stdenv
, lib
, dpkg
, fetchurl
, autoPatchelfHook
, wrapGAppsHook3

  # libs
, ffmpeg
, gtk3
, nss
, xorg
, libxkbcommon
, openssl
, mesa

, libudev0-shim
}:

stdenv.mkDerivation rec {
  pname = "utools";
  version = "5.0.0";
  src = fetchurl {
    url = "https://publish.u-tools.cn/version2/utools_${version}_amd64.deb";
    sha256 = "sha256-nlk6RLgs0XQ/EhtMaEgZS1O9Z+Zzb+Kj3o2b6zt1cMs=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    ffmpeg
    gtk3
    nss
    libxkbcommon
    openssl
    mesa
  ] ++ (with xorg; [
    libX11
    libXScrnSaver
    libXrandr
    libXext
    libxcb
    libXtst
    libXdamage
  ]);

  unpackPhase = ''
    runHook preUnpack
    ${dpkg}/bin/dpkg-deb -x ${src} ./
    runHook postUnpack
  '';

  runtimeDependencies = [ libudev0-shim ];

  installPhase = ''
    runHook preInstall

    substituteInPlace usr/share/applications/utools.desktop --replace /opt/uTools/ "$out/bin/"
    rm opt/uTools/resources/app.asar.unpacked/node_modules/leveldown/prebuilds/linux-x64/node.napi.musl.node

    mkdir -p $out/bin
    mv opt $out
    mv usr/share $out

    ln -s $out/opt/uTools/utools $out/bin/utools

    runHook postInstall
  '';

  meta = {
    homepage = "https://u.tools";
    license = lib.licenses.unfree;
  };
}

