{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # dev
    cmake
    rustup
    python3
    scala
    poetry
    bear
    scala
    nodejs
    yarn
    qemu
    man-pages
    ninja
    flamegraph
    gdb # to allow clion to find a debugger
    radare2

    # media and doc cli
    imagemagick
    pandoc
    ffmpeg
    poppler_utils
    syncplay
    handbrake
    calibre
    flac
    shntool
    cuetools
    picard
    sox
    audacity
    mediainfo
    lame
    # logchecker  # to be fixed
    # torrenttools  # to be fixed

    # extra cli
    w3m
    inotify-tools
    lm_sensors
    ccal
    rclone
    sshfs
    age
    openssl
    gh
    yt-dlp
    hyperfine
    gotty
    whois
    tealdeer # tldr in rust
    samba
    cifs-utils
    nfs-utils
    tokei
    smartmontools
    babelfish
    unixtools.xxd
    elf-info
    restic
    parallel
    (pkgs.lowPrio moreutils)
    python3Packages.afdko # Adobe Font Development Kit for OpenType
    qrcp
    grc # qrcode cp
    mlc
    p7zip
    android-tools

    git-filter-repo
    # git-branchless  # broken
    git-absorb
    git-revise

    # nix utils
    sops
    nurl
    nixpkgs-review
    nixpkgs-fmt
    nix-prefetch
    nix-output-monitor
    nix-init
    cntr
    bubblewrap
    nix-tree
    attic-client
    nvfetcher
    colmena

    # wine
    winePackages.full
    winetricks
    dxvk

    # networking cli
    v2ray
    wireguard-tools
    mtr
    shadowsocks-libev
    iproute2
    iptables
    nmap
    tcpdump
    q
    tun2socks
    nali
    tcping-go
    iptraf-ng # TODO: make it setcap
    cloudflare-warp

    # self-packaged cli
    python-ddns
    goauthing
    pb
    sharzyscripts
    music-tag
    sharzyscripts

    # tex
    python3.pkgs.pygments-extra
    latexrun
    zathura
    (texlive.combine {
      inherit (texlive) scheme-full;
      pkgFilter = pkg: lib.elem pkg.tlType [ "run" "bin" "doc" ];
    })

    typst
    typstyle

    # gui
    sioyek
    telegram-desktop
    flameshot
    zotero
    dropbox
    obsidian
    mpv
    feh
    anki
    thunderbird
    meld
    parsec-bin
    chromium
    imhex
    gtkwave
    remmina
    nicotine-plus

    # design
    gimp
    inkscape
    fontforge

    # TOTALLY PROPRIETARY
    wpsoffice
    mathematica
    utools
    zoom-us
    wemeet

    # ide
    jetbrains.clion
    jetbrains.rust-rover
    jetbrains.pycharm-professional
    jetbrains.goland
    jetbrains.idea-ultimate
    jetbrains.webstorm
    vscode

    # x cli
    xclip
    pavucontrol
    dconf

    beancount
    subconverter
  ];
}
