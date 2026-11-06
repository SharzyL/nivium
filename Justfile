default:
	@just --list

push-cache:
	attic push shz $(nix build --no-link --print-out-paths ".#telegram-desktop" ".#mpv" ".#sway" ".#attic" ".#attic-server")

update-keys:
	sops updatekeys secrets/*

update-pins:
	npins -d pkgs/npins update
	just update-rssbot

# npins cannot track release assets, so re-pin rssbot to its latest release (including pre-releases)
update-rssbot:
	tag=$(curl -fsSL https://api.github.com/repos/iovxw/rssbot/releases | jq -r '.[0].tag_name') && npins -d pkgs/npins add url "https://github.com/iovxw/rssbot/releases/download/$tag/rssbot-en-x86_64-unknown-linux-musl" --name rssbot

deploy-remote:
	nsw @remote akiko

