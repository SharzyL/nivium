{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # dev
    bear
    qemu
    man-pages
    flamegraph
    radare2
    rustfmt
    python3
    nodejs
    pnpm
    uv

    # media and doc cli
    imagemagick
    pandoc
    ffmpeg
    poppler-utils
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
    logchecker
    # torrenttools

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
    whois
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
    (lib.lowPrio moreutils)
    python3Packages.afdko # Adobe Font Development Kit for OpenType
    qrcp
    # mlc
    p7zip
    android-tools
    beancount
    subconverter
    go-grip
    gh

    git-filter-repo
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
    bubblewrap
    nix-tree
    attic-client
    nvfetcher
    colmena

    # wine
    wineWow64Packages.waylandFull
    winetricks
    dxvk

    # networking cli
    wireguard-tools
    mtr
    iproute2
    nmap
    tcpdump
    q
    tun2socks
    passt
    nali
    tcping-go
    iptraf-ng # TODO: make it setcap

    # self-packaged things
    goauthing
    pb
    sharzyscripts
    music-tag
    csync
    rdict
    bww

    # tex
    python3.pkgs.pygments-extra
    latexrun
    zathura
    texliveBasic

    typst

    # gui
    sioyek
    telegram-desktop
    snipaste
    zotero
    dropbox
    obsidian
    mpv
    feh
    anki
    thunderbird
    parsec-bin
    chromium
    nicotine-plus
    blender
    pavucontrol

    # design
    gimp
    inkscape
    fontforge

    # TOTALLY PROPRIETARY
    wpsoffice
    mathematica
    zoom-us

    # ide
    claude-code
  ];
}
