{ lib, runCommand, unzip, srcs }:

let
  mkRimeScheme = { pname, version, src, filter ? "*.yaml", ... }: runCommand "${pname}-${version}" { } ''
    mkdir -p "$out/share/rime-data"
    cp -r ${src}/${filter} "$out/share/rime-data"
  '';
in
{
  rime-prelude = mkRimeScheme srcs.rime-prelude;

  rime-luna-pinyin = mkRimeScheme srcs.rime-luna-pinyin;

  rime-double-pinyin = mkRimeScheme srcs.rime-double-pinyin;

  rime-dict = mkRimeScheme (srcs.rime-dict // { filter = "*.dict.yaml"; });

  rime-essay = mkRimeScheme (srcs.rime-essay // { filter = "essay.txt"; });

  rime-ice = mkRimeScheme (srcs.rime-ice // { filter = "{cn_dicts,rime_ice.dict.yaml}"; });
}

