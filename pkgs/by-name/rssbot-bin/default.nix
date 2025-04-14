{ stdenv
, lib
, autoPatchelfHook

, srcs
}:

stdenv.mkDerivation rec {
  inherit (srcs.rssbot) pname version src;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm555 ${src} $out/bin/rssbot

    runHook postInstall
  '';

  meta = {
    description = "Lightweight Telegram RSS notification bot. 用于消息通知的轻量级 Telegram RSS 机器人";
    homepage = "https://github.com/iovxw/rssbot/";
    mainProgram = "rssbot";
    license = lib.licenses.unlicense;
    platforms = [ "x86_64-linux" ];
  };
}

