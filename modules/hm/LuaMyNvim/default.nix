{ lib
, lua
, buildLuaPackage
}:

buildLuaPackage {
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

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/lua/${lua.luaversion}
    cp -rT $src $out/share/lua/${lua.luaversion}/LuaMyNvim
    runHook postInstall
  '';
}
