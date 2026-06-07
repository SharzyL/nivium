{ inputs, ... }:

final: prev:
let
  lib = final.lib;

  nixpkgs_master = (import inputs.nixpkgs_master {
    system = final.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  });

  versionGuard = pkg: version: drv: assert lib.assertMsg
    (!(final.lib.versionAtLeast pkg.version version))
    "expect '${pkg.pname}' version less than ${version}, get ${pkg.version}";
    drv
  ;
in
{
  fido2luks = versionGuard prev.fido2luks "0.3.0" (prev.fido2luks.overrideAttrs (oldAttrs: rec {
    patches = (prev.patches or [ ]) ++ [ ./patches/fido2luks-bump-libcryptsetup.patch ];
    cargoDeps = oldAttrs.cargoDeps.overrideAttrs (lib.const {
      inherit patches;
      outputHash = "sha256-3gVdJXs8Oih5btthATocMYmHwZwtwkCmPQTYXMKH5w0=";
    });
  }));

  latexrun = (prev.latexrun.overrideAttrs (oldAttrs: {
    patches = (prev.patches or [ ]) ++ [ ./patches/latexrun.patch ];
  }));

  # to prevent collision with rustup
  rust-analyzer = lib.hiPrio prev.rust-analyzer;

  # zoom-us = nixpkgs_master.zoom-us;

  firefox = prev.firefox.overrideAttrs (old: {
    buildCommand = old.buildCommand + ''
      substituteInPlace $out/share/applications/firefox.desktop \
        --replace "Exec=firefox" "Exec=env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy firefox"
    '';
  });

  firefox-devedition = prev.firefox-devedition.overrideAttrs (old: {
    buildCommand = old.buildCommand + ''
      substituteInPlace $out/share/applications/firefox-devedition.desktop \
        --replace "Exec=firefox-devedition" "Exec=env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy firefox-devedition"
    '';
  });

  chromium = prev.chromium.overrideAttrs (old: {
    buildCommand = old.buildCommand + ''
      desktopPath=$(realpath $out/share/applications/chromium-browser.desktop)
      rm $out/share/applications
      mkdir $out/share/applications
      cp "$desktopPath" $out/share/applications
      chmod +w $out/share/applications/chromium-browser.desktop
      substituteInPlace $out/share/applications/chromium-browser.desktop \
        --replace "Exec=chromium" "Exec=env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy chromium --password-store=basic"
    '';
  });

  iwd = prev.iwd.override {
    ell = final.ell.overrideAttrs (_: {
      postPatch = ''
        substituteInPlace ell/tls-suites.c \
          --replace 'params->prime_len < 192' 'params->prime_len < 128'
      '';
    });
  };

  anki = prev.anki.override { mpv-unwrapped = prev.mpv-unwrapped; }; # prevent anki from recompile

  my_ffmpeg = prev.ffmpeg-full.overrideAttrs (prevAttrs: {
    configureFlags = prevAttrs.configureFlags ++ [
      "--enable-libaribcaption"
    ];
    buildInputs = prevAttrs.buildInputs ++ [
      final.libaribcaption
    ];
  });

  mpv-unwrapped = prev.mpv-unwrapped.override {
    cddaSupport = true;
    libbluray = prev.libbluray;
    ffmpeg = final.my_ffmpeg;
  };

  vimPlugins = prev.vimPlugins.extend
    (vfinal: vprev:
      let
        removeLicense = name: vprev."${name}".overrideAttrs (oldAttrs: {
          meta = lib.removeAttrs oldAttrs.meta [ "license" ];
        });
      in
      {
        nvim-cmp = vprev.nvim-cmp.overrideAttrs (oldAttrs: {
          # https://github.com/hrsh7th/nvim-cmp/issues/1877
          src = final.fetchFromGitHub {
            owner = "hrsh7th";
            repo = "nvim-cmp";
            rev = "b356f2c80cb6c5bae2a65d7f9c82dd5c3fdd6038";
            hash = "sha256-ndZlp3GYReSgoxlhpddHofetbibxTEblBuBxbaPuCKY=";
          };

          patches = (oldAttrs.patches or [ ]) ++ [
            # merging https://github.com/hrsh7th/nvim-cmp/pull/1991
            # and https://github.com/hrsh7th/nvim-cmp/pull/1931
            ./patches/nvim-cmp-fix-tbl.patch
          ];
        });

        nui-nvim = vprev.nui-nvim.overrideAttrs (oldAttrs: {
          # https://github.com/MunifTanjim/nui.nvim/pull/365
          src = final.fetchFromGitHub {
            owner = "MunifTanjim";
            repo = "nui.nvim";
            rev = "8d3bce9764e627b62b07424e0df77f680d47ffdb";
            hash = "sha256-BYTY2ezYuxsneAl/yQbwL1aQvVWKSsN3IVqzTlrBSEU=";
          };
        });

        smartyank-nvim = removeLicense "smartyank-nvim";
        vim-argumentative = removeLicense "vim-argumentative";
        barbar-nvim = removeLicense "barbar-nvim";
      });

  go-grip = prev.go-grip.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./patches/go-grip.patch
    ];
  });

  mathematica = (prev.mathematica.override rec {
    version = "13.2.0";
    # the "modern" way of adding a path
    # `nix hash file (nix store add /path/to/file)`
    source = final.requireFile rec {
      hash = "sha256-YRUvl2H9SwpwDZx04ugd7ZnK5G+t88bzAObXsGGVhk0=";
      name = "Mathematica_${version}_BNDL_LINUX.sh";
      message = ''
        ${name} of hash ${hash} missing in nix store
      '';
      meta.license = final.lib.licenses.free; # to avoid the anonying license check
    };
  }).overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      ln -s $out/libexec/Mathematica/Executables/wolframscript $out/bin/wolframscript
    '';
  });
}
