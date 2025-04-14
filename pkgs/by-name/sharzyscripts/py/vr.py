#!/usr/bin/env python3

from argparse import ArgumentParser
from pathlib import Path
import shutil
import tempfile
import subprocess
import sys
import os

class Color:
   BLACK = '\033[1;30;48m'
   RED = '\033[1;31;48m'
   GREEN = '\033[1;32;48m'
   YELLOW = '\033[1;33;48m'
   BLUE = '\033[1;34;48m'
   MAGENTA = '\033[1;35;48m'
   CYAN = '\033[1;36;48m'
   WHITE = '\033[1;37;48m'
   UNDERLINE = '\033[4;37;48m'
   END = '\033[1;37;0m'
   GRAY = '\033[1;90;48m'

   @staticmethod
   def red(s):
       return f'{Color.RED}{s}{Color.END}'

   @staticmethod
   def yellow(s):
       return f'{Color.YELLOW}{s}{Color.END}'

   @staticmethod
   def gray(s):
       return f'{Color.GRAY}{s}{Color.END}'

   @staticmethod
   def blue(s):
       return f'{Color.BLUE}{s}{Color.END}'

   @staticmethod
   def cyan(s):
       return f'{Color.CYAN}{s}{Color.END}'

   @staticmethod
   def magenta(s):
       return f'{Color.MAGENTA}{s}{Color.END}'

   @staticmethod
   def green(s):
       return f'{Color.GREEN}{s}{Color.END}'

   @staticmethod
   def underline(s):
       return f'{Color.UNDERLINE}{s}{Color.END}'

def main():
    parser = ArgumentParser()
    parser.add_argument('files', metavar='FILE', nargs='*')
    args = parser.parse_args()

    files: list[str] = args.files

    if not files:
        for line in sys.stdin:
            files.append(line.strip('\r\n'))  # strip the trailing newline

    sys.stdin = open('/dev/tty', 'r')

    handle(args.files)

def handle(files: list[str]):
    vim_input_str = '\n'.join(files)
    editor = shutil.which('nvim') or shutil.which('vim')
    if editor is None:
        raise RuntimeError('no editor (nvim/vim) found in PATH')

    output_tmp = tempfile.NamedTemporaryFile(suffix='vr')
    output_tmp.write(vim_input_str.encode())
    output_tmp.flush()

    vim_proc = subprocess.Popen([editor, output_tmp.name])
    vim_proc.wait()

    output_tmp.seek(0)
    new_files = [line.decode().strip('\r\n') for line in output_tmp.readlines()]

    if files == new_files:
        print("names unchanged, quit")
        exit(0)

    if len(files) != len(new_files):
        print(Color.red(f'Error: {len(files)} files in, {len(new_files)} files out'), file=sys.stderr)
        while True:
            ans = input(Color.red('Choose: r(eedit)/q(uit)?'))
            if ans.startswith('r'):
               handle(files)
               break
            elif ans.startswith('q'):
               exit(0)
            else:
               continue
    else:
        for file, new_file in zip(files, new_files):
            if new_file == '':
                print(f'{Color.gray(file)} {Color.red("(delete)")}')
            elif file == new_file:
                print(f'{Color.gray(file + " (unchanged)")}')
            elif common_path := os.path.commonpath([file, new_file]):
                common_path_len = len(common_path)
                file_residue = file[common_path_len:]
                new_file_residue = new_file[common_path_len:]
                print(f'{Color.gray(common_path)}{{{Color.gray(file_residue)} -> {Color.blue(new_file_residue)}}}')
            else:
                print(f'{Color.gray(file)} -> {Color.blue(new_file)}')
        while True:
            ans = input(Color.red('Choose: y(es)/r(eedit)/q(uit)?'))
            if ans.startswith('r'):
               handle(files)
               break
            elif ans.startswith('q'):
               exit(0)
            elif ans.startswith('y'):
                for file, new_file in zip(files, new_files):
                    if new_file == '':
                        Path(file).unlink()
                    elif file != new_file:
                        Path(file).rename(Path(new_file))
                break
            else:
               continue



if __name__ == '__main__':
    main()
