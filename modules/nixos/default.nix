let
  dirFiles = path: (builtins.attrValues
    (builtins.mapAttrs
      (name: _: ./${path}/${name})
      (builtins.readDir (./. + "/${path}"))
    )
  );
in
{ ... }:
{
  imports = [
    ./base.nix
    ./home-base.nix
    ./graphics
    ./dhack
    ./systemd-hardening.nix
  ] ++ (dirFiles "services") ++ (dirFiles "programs");
}

