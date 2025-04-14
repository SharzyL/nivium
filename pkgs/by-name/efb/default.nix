{ python3, srcs, lib }:

let
  python-telegram-bot = python3.pkgs.callPackage ./python-telegram-bot.nix { };
  bullet = python3.pkgs.buildPythonPackage srcs.bullet;

  efb = python3.pkgs.buildPythonPackage {
    inherit (srcs.ehforwarderbot) pname version src;
    doCheck = false;
    propagatedBuildInputs = let ppkg = python3.pkgs; in [
      ppkg.cjkwrap
      ppkg.ruamel_yaml
      ppkg.typing-extensions
      ppkg.setuptools
      bullet
    ];
    meta = {
      homepage = "https://ehforwarderbot.readthedocs.io";
      license = lib.licenses.agpl3Only;
    };
  };

  search_msg = python3.pkgs.buildPythonPackage {
    inherit (srcs.efb-search_msg-middleware) pname version src;
    patches = [ ./search_msg_require.patch ];
    doCheck = false;
    propagatedBuildInputs = let ppkg = python3.pkgs; in [
      efb
      python-telegram-bot
      ppkg.python-magic
      ppkg.peewee
      ppkg.pyyaml
      ppkg.python-dateutil
    ];
    meta = {
      homepage = "https://github.com/catbaron0/efb-search_msg-middleware";
      # no license specified
    };
  };

  ews = python3.pkgs.buildPythonPackage {
    inherit (srcs.efb-wechat-slave) pname version src;
    doCheck = false;
    propagatedBuildInputs = let ppkg = python3.pkgs; in [
      efb
      ppkg.cjkwrap
      ppkg.pyyaml
      ppkg.requests
      ppkg.pillow
      ppkg.pypng
      ppkg.pyqrcode
      ppkg.python-magic
      ppkg.typing-extensions
      bullet
    ];
    meta = {
      homepage = "https://github.com/ehForwarderBot/efb-wechat-slave";
      license = lib.licenses.agpl3Only;
    };
  };

  etm = python3.pkgs.buildPythonPackage {
    inherit (srcs.efb-telegram-master) pname version src;
    doCheck = false;
    propagatedBuildInputs = let ppkg = python3.pkgs; in [
      efb
      python-telegram-bot
      ppkg.python-magic
      ppkg.ffmpeg-python
      ppkg.peewee
      ppkg.requests
      ppkg.pydub
      ppkg.ruamel_yaml
      ppkg.pillow
      ppkg.language-tags
      ppkg.retrying
      bullet
      ppkg.cjkwrap
      ppkg.humanize
      ppkg.pypng
      ppkg.typing-extensions
    ];
    meta = {
      homepage = "https://github.com/ehForwarderBot/efb-telegram-master";
      license = lib.licenses.agpl3Only;
    };
  };

in
(python3.withPackages (p: [ efb ews etm search_msg ])).overrideAttrs (old: {
  passthru = old.passthru // { inherit efb ews etm search_msg; };
})

