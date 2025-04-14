{ stdenv
, lib
}:

stdenv.mkDerivation rec {
  pname = "LuaMyNvim";
  version = "dev-1";

  src = with lib.fileset; toSource {
    root = ./.;
    fileset = unions [
      ./init.lua
      ./utils.lua
      ./parts
      ./plugins
    ];
  };

  buildCommand = ''
    mkdir -p $out/share/lua/5.1
    cp -rT ${src} $out/share/lua/5.1/${pname}
  '';
}
