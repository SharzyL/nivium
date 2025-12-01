{ inputs, ... }:

final: prev:
let
  nixpkgs_master = (import inputs.nixpkgs_master {
    system = final.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  });

  versionGuard = pkg: version: drv: assert final.lib.assertMsg
    (!(final.lib.versionAtLeast pkg.version version))
    "expect '${pkg.pname}' version less than ${version}, get ${pkg.version}";
    drv
  ;
in
{
  imhex = prev.imhex.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ [ "-DIMHEX_USE_GTK_FILE_PICKER=ON" ];
    nativeBuildInputs = old.nativeBuildInputs ++ [ final.wrapGAppsHook3 ];
  });

  fido2luks = versionGuard prev.fido2luks "0.3.0" (prev.fido2luks.overrideAttrs (oldAttrs: rec {
    patches = (prev.patches or [ ]) ++ [ ./patches/fido2luks-bump-libcryptsetup.patch ];
    cargoDeps = oldAttrs.cargoDeps.overrideAttrs (final.lib.const {
      inherit patches;
      outputHash = "sha256-3gVdJXs8Oih5btthATocMYmHwZwtwkCmPQTYXMKH5w0=";
    });
  }));

  latexrun = (prev.latexrun.overrideAttrs (oldAttrs: {
    patches = (prev.patches or [ ]) ++ [ ./patches/latexrun.patch ];
  }));

  # to prevent collision with rustup
  rust-analyzer = final.lib.hiPrio prev.rust-analyzer;

  zoom-us = nixpkgs_master.zoom-us;

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
        --replace "Exec=chromium" "Exec=env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy chromium"
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

  mpv-unwrapped = prev.mpv-unwrapped.override {
    cddaSupport = true;
    libbluray = prev.libbluray.override { withAACS = true; };
    ffmpeg = prev.ffmpeg.overrideAttrs (prevAttrs: {
      configureFlags = prevAttrs.configureFlags ++ [
        "--enable-libaribcaption"
      ];
      buildInputs = prevAttrs.buildInputs ++ [
        final.libaribcaption
      ];
    });
  };

  # telegram-desktop = prev.telegram-desktop.override {
  #   unwrapped = prev.telegram-desktop.unwrapped.overrideAttrs (oldAttrs: {
  #     cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
  #       "-DDESKTOP_APP_USE_PACKAGED_FONTS=ON"
  #     ];
  #     patches = (oldAttrs.patches or [ ]) ++ [
  #       ./patches/telegram-recent-sticker-limit.patch
  #       ./patches/telegram-discussion-group-button.patch
  #     ];
  #   });
  # };
  #

  # https://github.com/kovidgoyal/kitty/discussions/5959
  kitty = prev.kitty.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./patches/kitty-mouse.patch
    ];
  });

  vimPlugins = prev.vimPlugins.extend (vfinal: vprev: {
    # https://github.com/ahmedkhalf/project.nvim/issues/117
    project-nvim = vprev.project-nvim.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [ ]) ++ [
        ./patches/project-nvim-glob.patch
      ];
    });

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
    };
  }).overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      ln -s $out/libexec/Mathematica/Executables/wolframscript $out/bin/wolframscript
    '';
  });
}
