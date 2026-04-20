#!/usr/bin/env python3
import subprocess
import re
import curses
import json
import sys
from pathlib import Path
from datetime import datetime
from curses import window
from typing import TypedDict, NotRequired, cast


class LockedNode(TypedDict):
    lastModified: NotRequired[int]


class Node(TypedDict):
    locked: NotRequired[LockedNode]


class FlakeLock(TypedDict):
    nodes: NotRequired[dict[str, Node]]


def get_nixpkgs_lastmodified(direnv_path: str) -> int | None:
    flake_lock = Path(direnv_path).parent / "flake.lock"
    if not flake_lock.exists():
        return None
    try:
        with open(flake_lock) as f:
            data = cast(FlakeLock, json.load(f))
        nodes = data.get("nodes", {})
        nixpkgs = nodes.get("nixpkgs", {})
        locked = nixpkgs.get("locked", {})
        return locked.get("lastModified")
    except (json.JSONDecodeError, KeyError, OSError) as e:
        print(f"Warning: Failed to parse {flake_lock}: {e}", file=sys.stderr)
        return None


def clean_direnv(path: str) -> None:
    direnv = Path(path)
    # Delete symlinks in flake-inputs directory
    flake_inputs = direnv / "flake-inputs"
    if flake_inputs.exists():
        for item in flake_inputs.iterdir():
            if item.is_symlink():
                item.unlink()
    # Delete flake-profile-* symlinks (but keep .rc files)
    for item in direnv.glob("flake-profile-*"):
        if item.is_symlink() and not item.name.endswith(".rc"):
            item.unlink()


def clean_result(path: str) -> None:
    Path(path).unlink()


def get_gc_roots() -> list[tuple[str, float, bool, str]]:
    result = subprocess.run(
        ["nix-store", "--gc", "--print-roots"], capture_output=True, text=True
    )
    roots: dict[str, tuple[float, bool, str]] = {}

    for line in result.stdout.splitlines():
        # Match .direnv directories
        if match := re.search(r"(/\S+\.direnv\S*)", line):
            path = Path(match.group(1))
            for parent in [path] + list(path.parents):
                if parent.name == ".direnv":
                    try:
                        nixpkgs_time = get_nixpkgs_lastmodified(str(parent))
                        if nixpkgs_time:
                            roots[str(parent)] = (nixpkgs_time, False, "direnv")
                        else:
                            roots[str(parent)] = (
                                parent.stat().st_mtime,
                                True,
                                "direnv",
                            )
                    except (OSError, PermissionError) as e:
                        print(f"Warning: Cannot access {parent}: {e}", file=sys.stderr)
                    break

        # Match result or result-* symlinks
        if match := re.search(r"(/\S+/result(?:-\S+)?)\s", line):
            path_str = match.group(1)
            path = Path(path_str)
            if path.is_symlink():
                try:
                    roots[path_str] = (path.lstat().st_mtime, True, "result")
                except (OSError, PermissionError) as e:
                    print(f"Warning: Cannot access {path}: {e}", file=sys.stderr)

    return sorted([(k, v[0], v[1], v[2]) for k, v in roots.items()], key=lambda x: x[1])


def main(stdscr: window, roots: list[tuple[str, float, bool, str]]) -> set[int] | None:
    selected: set[int] = set()
    pos = 0
    scroll = 0
    last_key = 0

    _ = curses.curs_set(0)
    curses.use_default_colors()
    _ = curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_WHITE)
    _ = curses.init_pair(2, 8, -1)  # Bright black (gray)
    _ = curses.init_pair(3, curses.COLOR_GREEN, -1)  # Green for direnv
    _ = curses.init_pair(4, curses.COLOR_BLUE, -1)  # Blue for result

    while True:
        stdscr.clear()
        h, w = stdscr.getmaxyx()
        max_items = h - 2

        # Adjust scroll to keep pos visible
        if pos < scroll:
            scroll = pos
        elif pos >= scroll + max_items:
            scroll = pos - max_items + 1

        stdscr.addstr(
            0,
            0,
            f"Found {len(roots)} gc roots | Space:select d:delete q:quit",
            curses.A_BOLD,
        )

        for i in range(scroll, min(scroll + max_items, len(roots))):
            path, mtime, is_mtime, root_type = roots[i]
            dt = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M")
            if is_mtime and root_type == "direnv":
                dt += " (mtime)"
            mark = "[x]" if i in selected else "[ ]"

            # Remove .direnv suffix for direnv type, keep full path for result type
            if root_type == "direnv":
                display_path = path.removesuffix("/.direnv")
            else:
                display_path = path
            parent = str(Path(display_path).parent) + "/"
            name = Path(display_path).name

            # Add cursor arrow for current position
            cursor = "❯ " if i == pos else "  "
            prefix = f"{cursor}{mark} {dt} "
            row = i - scroll + 1
            available_width = w - len(prefix) - 1

            # Choose color based on type
            type_color = (
                curses.color_pair(3) if root_type == "direnv" else curses.color_pair(4)
            )

            stdscr.addstr(row, 0, prefix[:w])
            path_str = (parent + name)[:available_width]
            parent_len = min(len(parent), available_width)
            stdscr.addstr(parent[:parent_len], curses.color_pair(2))
            if parent_len < available_width:
                name_attr = type_color | curses.A_BOLD if i == pos else type_color
                stdscr.addstr(name[: available_width - parent_len], name_attr)

        stdscr.refresh()
        key: int = stdscr.getch()

        if key == ord("q"):
            return None
        elif key == ord(" "):
            selected ^= {pos}
            if pos < len(roots) - 1:
                pos += 1
        elif key == ord("g") and last_key == ord("g"):
            pos = 0
            last_key = 0
            continue
        elif key == ord("G"):
            pos = len(roots) - 1
        elif key == 4:  # Ctrl-D
            pos = min(pos + (h - 2) // 2, len(roots) - 1)
        elif key == 21:  # Ctrl-U
            pos = max(pos - (h - 2) // 2, 0)
        elif key == ord("d") and selected:
            return selected
        elif key in (curses.KEY_UP, ord("k")) and pos > 0:
            pos -= 1
        elif key in (curses.KEY_DOWN, ord("j")) and pos < len(roots) - 1:
            pos += 1

        last_key = key


if __name__ == "__main__":
    roots = get_gc_roots()
    if not roots:
        print("No gc roots found")
        exit(0)

    selected = curses.wrapper(main, roots)

    if not selected:
        exit(0)

    print(f"\nWill clean the following {len(selected)} items:")
    for idx in sorted(selected):
        print(f"  {roots[idx][0]}")

    confirm = input("\nConfirm deletion? (y/N): ").strip().lower()
    if confirm == "y":
        for idx in selected:
            path, _, _, root_type = roots[idx]
            if root_type == "direnv":
                clean_direnv(path)
            else:
                clean_result(path)
        print("Done!")
    else:
        print("Cancelled")
