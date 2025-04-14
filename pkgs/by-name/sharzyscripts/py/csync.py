#!/usr/bin/env python3

"""
A folder synchronization tool using inotify to monitor and replicate changes from source to target directory.

Usage:
    sync_folders.py <source_dir> <target_dir> [--ignore GLOB] [--git-ignore] [--no-delete] [--debug]

Options:
    <source_dir>            Source directory to monitor
    <target_dir>            Target directory to sync to
    --ignore GLOB           Glob pattern to ignore (can be specified multiple times)
    --git-ignore            Respect .gitignore files in source directory
    --no-delete             Do not sync deletion operations
    --debug                 Enable debug logging level
"""

import filecmp
import os
import sys
import pathspec
import shutil
from pathlib import Path
import pyinotify
from loguru import logger
import argparse
from typing import List, Any, Callable, Dict, Optional
import time
import threading


class TTLCache:
    def __init__(self, ttl_seconds: float):
        self.ttl = ttl_seconds
        # TODO: use a RWLock
        self.lock = threading.Lock()
        self._cache: Dict[
            str, Dict[str, Any]
        ] = {}  # {key: {'value': val, 'timestamp': time.time()}}

    def get(self, key: str) -> Optional[Any]:
        with self.lock:
            entry = self._cache.get(key)
            if entry and (time.time() - entry["timestamp"]) < self.ttl:
                return entry["value"]
            return None

    def set(self, key: str, val: Any = None) -> None:
        with self.lock:
            self._cache[key] = {"value": val, "timestamp": time.time()}

    def expire(self, callback: Callable[[str, Any], None]) -> None:
        with self.lock:
            current_time = time.time()
            expired_keys = [
                key
                for key, entry in self._cache.items()
                if (current_time - entry["timestamp"]) >= self.ttl
            ]

            for key in expired_keys:
                callback(key, self._cache[key]["value"])
                del self._cache[key]

    def __contains__(self, key: str) -> bool:
        with self.lock:
            return key in self._cache

    def __delitem__(self, key: str) -> None:
        with self.lock:
            if key not in self._cache:
                raise KeyError(f"Key '{key}' not found in cache")
            del self._cache[key]


class SyncHandler(pyinotify.ProcessEvent):
    """Handles inotify events and performs synchronization."""

    def __init__(
        self,
        source_dir: Path,
        target_dir: Path,
        ignore_patterns: List[str],
        git_ignore: bool,
        no_delete: bool,
    ):
        """
        Initialize the sync handler.

        Args:
            source_dir: Path to source directory
            target_dir: Path to target directory
            ignore_patterns: List of glob patterns to ignore
            git_ignore: Whether to respect .gitignore files
            no_delete: Whether to skip deletion operations
        """
        self.source_dir = source_dir
        self.target_dir = target_dir
        self.git_ignore = git_ignore
        self.no_delete = no_delete

        self.path_specs: List[pathspec.PathSpec] = []
        self.path_specs.append(pathspec.GitIgnoreSpec.from_lines(ignore_patterns))

        if self.git_ignore:
            self._load_gitignore_patterns(self.source_dir)

        """
        when vim writes a file, it performs the following steps:
            1. MOVE file to file~
            2. CREATE file
            3. MODIFY file
            4. ATTRIB file
            5. DELETE file~
        To avoid unnecessary sync operation,
        - When detecting a MOVED_FROM event, we add the relpath to moved_from_cache
        - When detecting a MOVED_TO event of file `xxx~`, and `xxx` in moved_from_cache,
          Add `xxx` to ephermeral_file_cache and remove `xxx` from moved_from_cache
          Deletion of `xxx` is not synced
        - When items in moved_from_cache expires, sync deletion
        - When detecting a CREATE, MODIFY event of file `xxx` and `xxx` in ephermeral_file_cache, ignore the event
        - When detecting a ATTRIB event of file `xxx` and `xxx` in ephermeral_file_cache, sync file and remove from ephermeral_file_cache
        - When items in ephermeral_file_cache expires, sync `xxx` and `xxx~`
        """
        self.moved_from_cache = TTLCache(ttl_seconds=0.1)
        self.ephermeral_file_cache = TTLCache(ttl_seconds=0.2)

        self.check_cache_thread = threading.Thread(target=self.check_cache_loop)
        self.check_cache_thread.daemon = True
        self.check_cache_thread.start()

    def check_cache_loop(self):
        while True:
            self.check_cache()
            time.sleep(0.1)

    def check_cache(self) -> None:
        def move_from_cache_expire(k: str, _):
            rel_path = k
            src_path = self.source_dir / rel_path
            dest_path = self.target_dir / rel_path
            if not src_path.exists() and dest_path.exists():
                logger.info(f"moved_from_cache expires, delete {rel_path}")
                self._delete_file(dest_path)

        def ephermeral_file_cache_expire(k: str, _):
            rel_path = k
            src_path = self.source_dir / rel_path
            dest_path = self.target_dir / rel_path
            if src_path.exists():
                logger.info(f"ephermeral_file_cache expires, sync {rel_path}")
                self._sync_file(src_path, dest_path)
            elif dest_path.exists():
                logger.info(f"ephermeral_file_cache expires, delete {rel_path}")
                self._delete_file(dest_path)

            rel_path_tilde = k + "~"
            tilde_src_path = self.source_dir / rel_path_tilde
            tilde_dest_path = self.target_dir / rel_path_tilde
            if tilde_src_path.exists():
                logger.info(f"ephermeral_file_cache expires, sync {rel_path_tilde}")
                self._sync_file(tilde_src_path, tilde_dest_path)
            # since we have not created tilde file on dest, no need to delete

        self.moved_from_cache.expire(move_from_cache_expire)
        self.ephermeral_file_cache.expire(ephermeral_file_cache_expire)

    def _load_gitignore_patterns(self, directory: Path) -> None:
        """Load .gitignore patterns from directory and its parents."""

        def load_ignore_file(f: Path):
            logger.info(f"loading ignore file {f}")
            self.path_specs.append(
                pathspec.GitIgnoreSpec.from_lines(f.read_text().splitlines())
            )

        gitignore_path = directory / ".gitignore"
        gitexclude_path = directory / ".git" / "info" / "exclude"
        if gitignore_path.exists():
            load_ignore_file(gitignore_path)
        if gitexclude_path.exists():
            load_ignore_file(gitexclude_path)

        # Recursively check parent directories
        if directory.parent != directory:  # Not root directory
            self._load_gitignore_patterns(directory.parent)

    def _should_ignore(self, path: Path) -> bool:
        return any(spec.match_file(path) for spec in self.path_specs)

    def _sync_file(self, src_path: Path, dest_path: Path) -> None:
        """Synchronize a single file from source to destination."""
        try:
            if src_path.is_dir():
                dest_path.mkdir(parents=True, exist_ok=True)
            else:
                dest_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src_path, dest_path)
        except Exception:
            logger.exception(f"failed to sync {src_path} to {dest_path}")

    def _delete_file(self, dest_path: Path) -> None:
        """Delete a file or directory in target."""
        try:
            if dest_path.exists():
                if dest_path.is_dir():
                    shutil.rmtree(dest_path)
                else:
                    dest_path.unlink()
        except Exception as e:
            logger.exception(f"failed to delete {dest_path}: {str(e)}")

    def process_IN_CREATE(self, event: pyinotify.Event) -> None:
        """Handle file/directory creation."""
        src_path = Path(event.pathname)
        rel_path = src_path.relative_to(self.source_dir)
        if self._should_ignore(rel_path):
            return

        # to ignore some quickly deleted files
        time.sleep(0.1)
        if src_path.exists():
            k = str(rel_path)
            if k in self.ephermeral_file_cache:
                logger.debug(f"ignore CREATE event on ephermeral file {k}")
            else:
                logger.info(f"detected CREATE event on {rel_path}, syncing")
                dest_path = self.target_dir / rel_path
                self._sync_file(src_path, dest_path)
        else:
            logger.debug(
                f"detected CREATE event on {rel_path}, but the file is missing"
            )

    def process_IN_DELETE(self, event: pyinotify.Event) -> None:
        """Handle file/directory deletion."""
        if self.no_delete:
            return

        src_path = Path(event.pathname)
        rel_path = src_path.relative_to(self.source_dir)
        if self._should_ignore(rel_path):
            logger.debug(f"detected DELETE event on {rel_path}, ignore")
            return

        dest_path = self.target_dir / rel_path
        if dest_path.exists():
            logger.info(f"detected DELETE event on {rel_path}, syncing delete")
            self._delete_file(dest_path)
        else:
            logger.debug(
                f"detected DELETE event on {rel_path}, but dest file is missing"
            )

    def process_IN_MODIFY(self, event: pyinotify.Event) -> None:
        """Handle file modification."""
        src_path = Path(event.pathname)
        rel_path = src_path.relative_to(self.source_dir)
        if self._should_ignore(rel_path):
            return

        # Skip directories (they don't get modified, only their contents)
        if src_path.is_dir():
            return

        if src_path.exists():
            k = str(rel_path)
            if k in self.ephermeral_file_cache:
                logger.debug(f"ignore MODIFY event on ephermeral file {k}")
            else:
                dest_path = self.target_dir / rel_path
                logger.info(f"detected MODIFY event on {rel_path}, syncing")
                self._sync_file(src_path, dest_path)
        else:
            logger.debug(
                f"detected MODIFY event on {rel_path}, but the file is missing"
            )

    def process_IN_MOVED_FROM(self, event: pyinotify.Event) -> None:
        """Handle file/directory move (source)."""
        if self.no_delete:
            return

        src_path = Path(event.pathname)
        rel_path = src_path.relative_to(self.source_dir)
        if self._should_ignore(rel_path):
            return

        dest_path = self.target_dir / rel_path
        if dest_path.exists():
            k = str(rel_path)
            logger.debug(f"add {k} to moved_from_cache")
            self.moved_from_cache.set(str(rel_path))
        else:
            logger.debug(
                f"detected MOVED_FROM event on {rel_path}, but dest file is missing"
            )

    def process_IN_MOVED_TO(self, event: pyinotify.Event) -> None:
        """Handle file/directory move (destination)."""
        src_path = Path(event.pathname)
        rel_path = src_path.relative_to(self.source_dir)
        if self._should_ignore(rel_path):
            return

        if src_path.exists():
            k = str(rel_path)
            if k.endswith('~') and k[:-1] in self.moved_from_cache:
                logger.debug(f"detect ephermeral file {k}")
                del self.moved_from_cache[k[:-1]]
                self.ephermeral_file_cache.set(k[:-1])
            else:
                logger.info(f"detected MOVED_TO event on {rel_path}, syncing")
                dest_path = self.target_dir / rel_path
                self._sync_file(src_path, dest_path)
        else:
            logger.debug(
                f"detected MOVED_TO event on {rel_path}, but the file is missing"
            )

    def process_IN_ATTRIB(self, event: pyinotify.Event) -> None:
        """Handle metadata changes (permissions, timestamps, etc.)."""
        src_path = Path(event.pathname)
        rel_path = src_path.relative_to(self.source_dir)
        if self._should_ignore(rel_path) or src_path.is_dir():
            return

        dest_path = self.target_dir / rel_path

        if src_path.exists():
            k = str(rel_path)
            if k in self.ephermeral_file_cache:
                logger.debug(f"remove {k} from ephermeral_file_cache")
                del self.ephermeral_file_cache[k]

            logger.info(f"detected ATTRIB event on {rel_path}, syncing")
            self._sync_file(src_path, dest_path)
        else:
            logger.debug(
                f"detected ATTRIB event on {rel_path}, but the file is missing"
            )

    def initial_sync(self, source_dir: Path, target_dir: Path, fast: bool = False) -> None:
        """
        Perform initial synchronization of all files.

        Args:
            source_dir: Source directory path
            target_dir: Target directory path
            handler: Sync handler instance with ignore patterns
        """
        logger.info(f"performing initial sync from {source_dir} to {target_dir}")

        file_count = 0
        synced_file_count = 0
        for root, dirs, files in os.walk(source_dir, topdown=True):
            root_path = Path(root)
            file_count += len(dirs) + len(files)

            # Process directories first
            updated_dirs = []
            for dirname in dirs:
                dir_path = root_path / dirname
                rel_path = dir_path.relative_to(source_dir)
                if not self._should_ignore(rel_path):
                    updated_dirs.append(dirname)
                    dest_path = target_dir / rel_path
                    if not dest_path.exists():
                        logger.debug(f"creating synced directory {rel_path}")
                        dest_path.mkdir(parents=True, exist_ok=True)
                        synced_file_count += 1
            dirs[:] = updated_dirs

            # Then process files
            for filename in files:
                file_path = root_path / filename
                rel_path = file_path.relative_to(source_dir)
                dest_path = target_dir / rel_path

                if not self._should_ignore(file_path):
                    if not dest_path.exists() or not filecmp.cmp(file_path, dest_path, shallow=fast):
                        synced_file_count += 1
                        shutil.copy2(file_path, dest_path)
                        logger.debug(f"syncing file {rel_path}")

        logger.info(
            f"initial sync completed, {synced_file_count}/{file_count} file changed"
        )


def setup_logging(debug: bool = False) -> None:
    """Configure loguru logging with colored output."""
    logger.remove()  # Remove default handler

    # Custom format with colors
    fmt = "<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | <level>{level: <8}</level> | <level>{message}</level>"

    logger.add(
        sys.stderr,
        colorize=True,
        format=fmt,
        level="DEBUG" if debug else "INFO",
        backtrace=True,
        diagnose=debug,
    )


def main():
    parser = argparse.ArgumentParser(
        prog="csync",
        description="Folder synchronization tool using inotify"
    )
    parser.add_argument("source_dir", help="Source directory to monitor")
    parser.add_argument("target_dir", help="Target directory to sync to")
    parser.add_argument(
        "--ignore",
        action="append",
        default=[],
        help="Glob pattern to ignore (can be specified multiple times)",
    )
    parser.add_argument(
        "--no-git-ignore",
        action="store_true",
        help="Do not respect .gitignore files in source directory",
    )
    # TODO: check its correctness
    parser.add_argument(
        "--no-delete", action="store_true", help="Do not sync deletion operations"
    )
    parser.add_argument(
        "--fast-initial-sync", action="store_true", help="shallow file comparison on initial sync"
    )
    parser.add_argument(
        "--debug", action="store_true", help="Enable debug logging level"
    )

    args = parser.parse_args()

    # Configure logging
    setup_logging(args.debug)

    # Validate directories
    source_dir = Path(args.source_dir).resolve()
    target_dir = Path(args.target_dir).resolve()

    if not source_dir.exists():
        logger.error(f"source directory does not exist: {source_dir}")
        sys.exit(1)

    if not source_dir.is_dir():
        logger.error(f"source path is not a directory: {source_dir}")
        sys.exit(1)

    # Create target directory if it doesn't exist
    if not target_dir.exists():
        logger.info(f"create target directory {target_dir}")
        target_dir.mkdir()

    # Initialize handler
    handler = SyncHandler(
        source_dir=source_dir,
        target_dir=target_dir,
        ignore_patterns=args.ignore,
        git_ignore=not args.no_git_ignore,
        no_delete=args.no_delete,
    )

    # Perform initial sync
    handler.initial_sync(source_dir, target_dir, fast=args.fast_initial_sync)

    # Set up inotify watcher
    wm = pyinotify.WatchManager()
    mask = (
        pyinotify.IN_CREATE  # File/dir created
        | pyinotify.IN_DELETE  # File/dir deleted
        | pyinotify.IN_MODIFY  # File modified
        | pyinotify.IN_MOVED_FROM  # File moved from this location
        | pyinotify.IN_MOVED_TO  # File moved to this location
        | pyinotify.IN_ATTRIB  # Metadata changed
    )

    # Watch recursively
    notifier = pyinotify.Notifier(wm, handler)
    notifier.coalesce_events()
    wdd = wm.add_watch(str(source_dir), mask, rec=True, auto_add=True)

    logger.info(f"starting to monitor {source_dir} for changes...")

    try:
        notifier.loop()
    except KeyboardInterrupt:
        logger.info("received interrupt signal, shutting down...")
    except Exception as e:
        logger.exception(f"Unexpected error: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
