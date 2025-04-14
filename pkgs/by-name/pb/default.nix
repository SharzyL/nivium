{ runCommand

, srcs
}:

let
  inherit (srcs.pb) pname version src;
in

runCommand pname { inherit pname version; } ''
  mkdir -p $out/bin $out/share/fish/vendor_completions.d $out/share/zsh/site-functions
  cp ${src}/scripts/pb $out/bin
  cp ${src}/scripts/pb.fish $out/share/fish/vendor_completions.d
  cp ${src}/scripts/_pb $out/share/zsh/site-functions
''
