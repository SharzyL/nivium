default:
	@just --list

common_rsync_args := "-e 'env DISPLAY=:0 ssh' . -rAP --exclude .git --exclude .direnv --exclude Justfile --exclude .gcroots --exclude venv"
hm_rsync_args := "--exclude nixos"
darwin_rsync_args := "--rsync-path=.nix-profile/bin/rsync"
extra_rsync_args := ""

to-ideal server:
	rsync {{common_rsync_args}} {{hm_rsync_args}} --include home/ideal.nix --exclude "home/*" {{extra_rsync_args}} {{server}}:flake/

to-simple server:
	rsync {{common_rsync_args}} {{hm_rsync_args}} --include home/simple.nix --exclude "home/*" {{extra_rsync_args}} {{server}}:flake/

to-ideal-sgx:
	nix copy ".#homeConfigurations.ideal-sgx.activationPackage" --to ssh-ng://sgx1 --no-check-sigs
	ssh sgx1 $(nix build --no-link --print-out-paths ".#homeConfigurations.ideal-sgx.activationPackage")/activate

push-cache:
	attic push shz $(nix build --no-link --print-out-paths ".#telegram-desktop" ".#mpv" ".#sway" ".#attic" ".#attic-server")

update-keys:
	fd '.*\.yml|.*\.yaml' secrets | xargs -n1 sops updatekeys

update-nvfethcer:
	cd pkgs && nvfetcher

deploy-remote:
	nsw
	colmena --experimental-flake-eval apply --verbose --on @remote

