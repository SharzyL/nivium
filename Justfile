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

update-pins:
	npins -d pkgs/npins update
	just update-rssbot

# npins cannot track release assets, so re-pin rssbot to its latest release (including pre-releases)
update-rssbot:
	tag=$(curl -fsSL https://api.github.com/repos/iovxw/rssbot/releases | jq -r '.[0].tag_name') && npins -d pkgs/npins add url "https://github.com/iovxw/rssbot/releases/download/$tag/rssbot-en-x86_64-unknown-linux-musl" --name rssbot

deploy-remote:
	nsw
	colmena apply --verbose --on @remote

