#!/usr/bin/env python3

import music_tag
from argparse import ArgumentParser
from pathlib import Path
import logging


def main():
    parser = ArgumentParser()
    parser.add_argument('files', metavar='FILE', nargs='+')
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger('cover-export')
    handle(args, logger)


def handle(args, logger):
    for f in args.files:
        p = Path(f)
        if not p.is_dir():
            logger.critical(f'{p} is not a directory')
            exit(1)
        cover_path = p / 'cover.jpg'
        if cover_path.exists():
            logger.info(f'{cover_path} exists, skip it')
            continue
        flacs = sorted(p.glob('*.flac'))
        if not flacs:
            logger.critical(f'no flac is found in {p}')
        flac = flacs[0]
        flac_tags = music_tag.load_file(flac)
        artwork = flac_tags['artwork'].value
        (p / 'cover.jpg').write_bytes(artwork.data)
        artwork_size_kb = len(artwork.data) / 1024.
        logger.info(f'{p} exported ({artwork_size_kb} kb)')


if __name__ == '__main__':
    main()
