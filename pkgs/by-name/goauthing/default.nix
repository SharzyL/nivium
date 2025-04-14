{ pkgs, fetchFromGitHub, lib, srcs }:

pkgs.buildGoModule {
  inherit (srcs.goauthing) pname version;

  # goconvey -> gopherjs -> x/sys and x/sys requires go 1.17
  src = fetchFromGitHub {
    owner = "SharzyL";
    repo = "GoAuthing";
    rev = "f934b9cf96738b585138927caf90b366a6d22c65";
    sha256 = "sha256-c6YibXrdRpw9QlJIKITIyzpwXmG3cTIgEFp0ci4L9Fg=";
  };

  vendorHash = "sha256-rRVi5Jl6TkL6+qLNuIoCpSh/27NDSBj/e6X6ObLzQo4=";
  subPackages = [ "cli" ];

  postInstall = ''
    mv $out/bin/cli $out/bin/auth-thu
  '';

  meta = {
    homepage = "https://github.com/z4yx/GoAuthing";
    license = lib.licenses.gpl3Only;
  };
}
