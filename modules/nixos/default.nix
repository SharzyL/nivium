let
  dirFiles = path: with builtins; (attrValues
    (mapAttrs
      (name: value: ./${path}/${name})
      (readDir (./. + "/${path}"))
    )
  );
in
{
  default = ({ ... }: {
    imports = [
      ./base.nix
      ./home-base.nix
      ./graphics
      ./dhack
      ./systemd-hardening.nix
    ] ++ (dirFiles "services") ++ (dirFiles "programs");
  });
}

