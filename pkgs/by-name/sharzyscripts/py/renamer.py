#!/usr/bin/env python3

import music_tag
from argparse import ArgumentParser
from pathlib import Path
import logging


class Color:
    BLACK = "\033[1;30;48m"
    RED = "\033[1;31;48m"
    GREEN = "\033[1;32;48m"
    YELLOW = "\033[1;33;48m"
    BLUE = "\033[1;34;48m"
    MAGENTA = "\033[1;35;48m"
    CYAN = "\033[1;36;48m"
    WHITE = "\033[1;37;48m"
    UNDERLINE = "\033[4;37;48m"
    END = "\033[1;37;0m"
    GRAY = "\033[1;90;48m"

    @staticmethod
    def red(s):
        return f"{Color.RED}{s}{Color.END}"

    @staticmethod
    def yellow(s):
        return f"{Color.YELLOW}{s}{Color.END}"

    @staticmethod
    def gray(s):
        return f"{Color.GRAY}{s}{Color.END}"

    @staticmethod
    def blue(s):
        return f"{Color.BLUE}{s}{Color.END}"

    @staticmethod
    def cyan(s):
        return f"{Color.CYAN}{s}{Color.END}"

    @staticmethod
    def magenta(s):
        return f"{Color.MAGENTA}{s}{Color.END}"

    @staticmethod
    def green(s):
        return f"{Color.GREEN}{s}{Color.END}"

    @staticmethod
    def underline(s):
        return f"{Color.UNDERLINE}{s}{Color.END}"


MUSIC_SUFFIXES = [".flac", ".mp3", ".m4a"]
OTHER_SUFFIXES = [".jpg", ".pdf", ".png", ".log", ".cue", ".txt"]
IGNORE_SUFFIXES = [".m3u", ".m3u8"]
KNOWN_PARTS = ["cover.jpg", "Scans", "Artwork"]


def main():
    parser = ArgumentParser()
    parser.add_argument("files", metavar="FILE", nargs="+")
    parser.add_argument("--year")
    parser.add_argument("--artist")
    parser.add_argument(
        "--per-track-artist", action="store_true", help="add artist name in each track"
    )
    parser.add_argument("--album")
    parser.add_argument("-e", "--extra", action="append", default=[])
    parser.add_argument("--formats")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("renamer")
    handle(args, logger)


def handle(args, logger):
    def get_meta(file, tags, mname):
        metas = tags.raw[mname].values
        if len(metas) > 1:
            print(Color.gray(f'warning: multiple meta "{mname}" in "{file}": {metas}'))
            return metas[0]
        elif len(metas) == 0:
            logger.fatal(f'no meta "{mname}" in "{file}": {metas}')
            exit(-1)
        else:
            return metas[0]

    def format_len(length):
        minutes = int(float(length) / 60)
        seconds = int(float(length) - 60 * minutes)
        return f"{minutes}:{seconds}"

    def format_media(media: str) -> str:
        if media.lower() == "digital media":
            return "WEB"
        else:
            return media

    def sanitize_name(name):
        if ":" in name or "/" in name:
            print(Color.gray(f"warning: detect specital character in {name}"))
        return (
            name.replace(":", "-")
            .replace("/", "／")
            .replace("*", "-")
            .replace("?", "")
            .replace("\\", "-")
            .replace("<", "-")
            .replace(">", "-")
            .replace('"', "'")
        )

    for f in args.files:
        if len(args.files) > 1:
            print(f'{Color.UNDERLINE}Prepare to rename "{f}"{Color.END}')
        p = Path(f)
        if not p.exists():
            logger.critical(f'"{p}" does not exists, abort')
            exit(-1)
        if not p.is_dir():
            logger.critical(f'"{p}" is not a directory, abort')
            exit(-1)
        if not (p / "cover.jpg").exists():
            print(Color.yellow(f'warning: "{p}/cover.jpg" does not exist'))

            for candidate in (
                "Cover.jpg",
                "Folder.jpg",
                "folder.jpg",
                "front.jpg",
                "Front.jpg",
            ):
                if (p / candidate).exists():
                    yn = input(f"move {candidate} to cover.jpg (y/n)")
                    if yn.lower() == "y":
                        (p / candidate).rename(p / "cover.jpg")

        year = None
        album_artist = None
        album = None
        label = None
        catalog_number = None
        totaldiscs = None
        media = None
        extra = []

        sample_rates = set()
        bitlens = set()
        mp3_bitrates = set()

        formats = set()
        assets = []
        other_formats = set()
        rename_plans = []

        if (p / "Scans").exists():
            assets.append("Scans")

        if (p / "Artwork").exists():
            assets.append("Artwork")

        for child in sorted(p.glob("**/*")):
            if child.relative_to(p).parts[0] in KNOWN_PARTS:
                continue
            if child.is_dir():
                continue
            relative_dir = str(child.parent.relative_to(p))
            suffix = child.suffix.lower()
            if suffix in MUSIC_SUFFIXES:
                tags = music_tag.load_file(child)
                formats.add(suffix[1:].upper())

                def update_meta(new_val, old_val, meta_name):
                    if old_val is not None and new_val != old_val:
                        print(
                            Color.yellow(
                                f'warning: inconsistent {meta_name} "{old_val}" and "{new_val}" ({child.name})'
                            )
                        )
                        return old_val
                    elif old_val is None:
                        return new_val
                    else:
                        return old_val

                def cur_meta(name):
                    return get_meta(child, tags, name)

                # update album data, check consistency
                album = update_meta(sanitize_name(cur_meta("album")), album, "album")
                album_artist = update_meta(
                    sanitize_name(cur_meta("albumartist")), album_artist, "album_artist"
                )

                year = update_meta(cur_meta("year"), year, "album_artist")
                if year is not None and "." in year:
                    logger.critical(
                        f'year "{year}" in file "{child}" should not be separated by "."'
                    )

                totaldiscs = update_meta(
                    int(cur_meta("totaldiscs")), totaldiscs, "totaldiscs"
                )
                label = update_meta(tags.raw.get("label", default=None), label, "label")
                catalog_number = update_meta(
                    tags.raw.get("catalognumber", default=None),
                    catalog_number,
                    "catalog_number",
                )
                media = update_meta(tags.raw.get("media", default=None), media, "media")

                # assert existence of these fields
                discnumber = int(get_meta(child, tags, "discnumber"))
                get_meta(child, tags, "totaltracks")
                get_meta(child, tags, "artwork")

                sample_rate = get_meta(child, tags, "#samplerate")
                sample_rates.add(sample_rate)
                bitlen = (
                    16
                    if child.suffix == ".mp3"
                    else get_meta(child, tags, "#bitspersample")
                )
                bitlens.add(bitlen)
                bit_rate = get_meta(child, tags, "#bitrate")
                if child.suffix == ".mp3":
                    mp3_bitrates.add(bit_rate)

                title: str = sanitize_name(get_meta(child, tags, "tracktitle"))
                tracknumber = get_meta(child, tags, "tracknumber")
                ext = child.suffix
                cur_artist = sanitize_name(get_meta(child, tags, "artist"))
                length = get_meta(child, tags, "#length")

                new_name = None
                if args.per_track_artist:
                    new_name = f"{tracknumber:>02} - {cur_artist} - {title}{ext}"
                else:
                    new_name = f"{tracknumber:>02} - {title}{ext}"
                assert totaldiscs is not None  # make type checker happy
                if totaldiscs > 1:
                    new_name = f"{discnumber}." + new_name

                encoding_info = (
                    f"{bitlen}bits x {sample_rate}Hz {int(bit_rate/1000)}kbps"
                )
                meta_info = f"{Color.cyan(format_len(length))} {Color.green(album_artist)} {Color.gray(encoding_info)}"
                if child.name != new_name:
                    print(
                        f'{Color.gray(relative_dir + "/")}{Color.blue(child.name)} -> {Color.red(new_name)} {meta_info}'
                    )
                    rename_plans.append((child, child.with_name(new_name)))
                else:
                    print(
                        f'{Color.gray(relative_dir + "/")}{Color.blue(child.name)} {Color.gray("(unchanged)")} {meta_info}'
                    )
            elif suffix in OTHER_SUFFIXES:
                print(
                    f'{Color.gray(relative_dir + "/")}{Color.blue(child.name)} {Color.gray("(non-music file, ignored)")}'
                )
                other_formats.add(suffix[1:].upper())
            elif suffix in IGNORE_SUFFIXES:
                continue
            else:
                print(Color.yellow(f'warning: Unknown file type "{child}"'))

        if len(sample_rates) > 1:
            print(Color.yellow(f"warning: mixed sample rate: {sample_rates}"))
        # ignore sample_rate meta for now

        if len(bitlens) > 1:
            print(Color.yellow(f"warning: mixed bit depth: {bitlens}"))
        elif len(bitlens) > 0:
            bl = bitlens.pop()
            if bl > 16:
                extra.append(f"{bl}bit")

        if len(mp3_bitrates) > 1:
            print(Color.yellow(f"warning: mixed mp3 bitrate: {mp3_bitrates}"))
        elif len(mp3_bitrates) > 0:
            bl = mp3_bitrates.pop()
            bl_kbps = int(bl / 1000)
            extra.append(f"{bl_kbps}kbps")

        if totaldiscs == None:
            logging.critical(f"empty music collection (since totaldiscs is None)")
        elif totaldiscs > 1:
            extra.append(f"{totaldiscs}CD")

        if media is None:
            print(Color.yellow("warning: no media specified"))
        else:
            extra.append(" ".join(map(format_media, media)))

        if catalog_number is not None:
            catalog_number_text = " ".join(catalog_number)
            extra.append(f"{catalog_number_text}")

        for e in args.extra:
            extra.append(e)

        format_str = "+".join(
            sorted(list(formats)) + sorted(list(other_formats)) + assets
        )
        extra_str = "".join(f"[{e}]" for e in extra)

        # TODO: handle the case that album title contains special characters
        new_name = f"{album_artist} - [{year}] {album} [{format_str}]{extra_str}"
        if p.name != new_name:
            print(f"{Color.blue(p.name)} -> {Color.red(new_name)}")
            rename_plans.append((p, p.absolute().with_name(new_name)))
        else:
            print(f'{Color.blue(p.name)} {Color.gray("(unchanged)")}')

        if rename_plans:
            confirm = input("Sure to continue? (y/n)")
            if confirm.lower() == "y":
                for original, new in rename_plans:
                    original.rename(new)
            else:
                print("aborted")
        else:
            print("nothing to rename")

        print()


if __name__ == "__main__":
    main()
