{ pkgs, lib, srcs }:

pkgs.buildGoModule {
  inherit (srcs.goauthing) pname version src;

  vendorHash = "sha256-Lwx3Z+BXFf2GWcJjTKEt4gZ7LO+UIbile7U7N/1+quU=";
  subPackages = [ "cli" ];

  postInstall = ''
    mv $out/bin/cli $out/bin/auth-thu
  '';

  meta = {
    homepage = "https://github.com/z4yx/GoAuthing";
    license = lib.licenses.gpl3Only;
  };
}
