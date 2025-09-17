{ lib
, rustPlatform

, srcs
}:

rustPlatform.buildRustPackage {
  inherit (srcs.elf-info) pname version src;

  cargoHash = "sha256-JSCdMGScpeA5q6++veuQ8li3qVTuB0XdJ1yacsqgBDg=";

  meta = with lib; {
    description = "Inspect and dissect an ELF file with pretty formatting";
    homepage = "https://crates.io/crates/elf-info";
    license = licenses.gpl3Only;
  };
}
