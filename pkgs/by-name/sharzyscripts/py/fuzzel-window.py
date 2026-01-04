#!/usr/bin/env python3
"""
Fuzzel-based window switcher for niri compositor.
Lists all windows in fuzzel and focuses the selected one.
"""

import json
import os
import subprocess
import sys
from pathlib import Path


def get_windows():
    """Get list of windows from niri."""
    try:
        result = subprocess.run(
            ["niri", "msg", "--json", "windows"],
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error getting windows from niri: {e}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON from niri: {e}", file=sys.stderr)
        sys.exit(1)


def get_workspaces():
    """Get list of workspaces from niri and create ID to name mapping."""
    try:
        result = subprocess.run(
            ["niri", "msg", "--json", "workspaces"],
            capture_output=True,
            text=True,
            check=True,
        )
        workspaces = json.loads(result.stdout)

        # Build mapping from workspace ID to name (or ID if name is null)
        workspace_map = {}
        for ws in workspaces:
            ws_id = ws.get("id")
            ws_name = ws.get("name")
            # Use name if available, otherwise fall back to ID
            workspace_map[ws_id] = ws_name if ws_name else str(ws_id)

        return workspace_map
    except subprocess.CalledProcessError as e:
        print(f"Error getting workspaces from niri: {e}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error parsing workspaces JSON from niri: {e}", file=sys.stderr)
        sys.exit(1)


def parse_icon_from_desktop_file(desktop_file):
    """Parse Icon field from a desktop entry file."""
    try:
        with open(desktop_file, 'r', encoding='utf-8') as f:
            in_desktop_entry = False
            for line in f:
                line = line.strip()

                # Track if we're in [Desktop Entry] section
                if line == "[Desktop Entry]":
                    in_desktop_entry = True
                elif line.startswith("[") and line.endswith("]"):
                    in_desktop_entry = False

                # Look for Icon= field in [Desktop Entry] section
                if in_desktop_entry and line.startswith("Icon="):
                    return line.split("=", 1)[1].strip()
    except (OSError, UnicodeDecodeError):
        pass
    return None


def get_xdg_data_dirs():
    """Get list of XDG data directories."""
    xdg_data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")
    xdg_data_home = os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local" / "share"))

    # Prepend XDG_DATA_HOME to the search path
    dirs = [xdg_data_home] + xdg_data_dirs.split(":")
    return [Path(d) for d in dirs if d]


def find_icon_by_app_id(app_id):
    """Find icon name from desktop entry using app_id."""
    if not app_id:
        return None

    # Search for {app_id}.desktop in XDG data directories
    for data_dir in get_xdg_data_dirs():
        desktop_file = data_dir / "applications" / f"{app_id}.desktop"
        if desktop_file.exists():
            icon = parse_icon_from_desktop_file(desktop_file)
            if icon:
                return icon

    return None


def find_icon_by_binary_path(pid, title=""):
    """Find icon name from desktop entry by following binary path."""
    try:
        # Get binary path from /proc/{pid}/exe
        exe_path = Path(f"/proc/{pid}/exe")
        if not exe_path.exists():
            return None

        binary_path = exe_path.resolve()
        binary_name = binary_path.name

        # Skip xwayland and xwayland-satellite as they are wrapper processes
        if "xwayland" in binary_name.lower():
            title_info = f" ({title})" if title else ""
            print(f"Windows with title '{title}' is using xwayland", file=sys.stderr)
            return None

        # Look for desktop entries in {binary_dir}/../share/applications
        share_dir = binary_path.parent.parent / "share" / "applications"

        if not share_dir.exists():
            return None

        # Search for desktop files
        for desktop_file in share_dir.glob("*.desktop"):
            icon = parse_icon_from_desktop_file(desktop_file)
            if icon:
                return icon

    except (OSError, RuntimeError):
        pass

    return None


def get_icon_name(pid, app_id, title=""):
    """
    Get icon name for a window.
    First tries to find by app_id in XDG_DATA_DIRS,
    then falls back to binary path search, and finally to app_id itself.
    """
    # If we have an app_id, try to find desktop file by app_id first
    if app_id:
        icon = find_icon_by_app_id(app_id)
        if icon:
            return icon

    # Try binary path search (for empty app_id or when app_id lookup failed)
    if pid:
        icon = find_icon_by_binary_path(pid, title)
        if icon:
            return icon

    # Fallback to app_id if we have one, otherwise "window"
    if app_id:
        return app_id

    return "window"


def format_window_entry(window, workspace_map):
    """Format a window entry for display in fuzzel with icon support."""
    title = window.get("title", "Untitled")
    app_id = window.get("app_id", "")
    workspace_id = window.get("workspace_id")
    pid = window.get("pid")

    # Get workspace name from map, fall back to ID if not found
    workspace_display = workspace_map.get(workspace_id, str(workspace_id) if workspace_id else "?")

    # Use app_id for display, or "window" if empty
    display_app_id = app_id or "window"

    # Build display string: [workspace_name] AppID - Title
    display_text = f"[{workspace_display}] {display_app_id} - {title}"

    # Get icon name from desktop entry
    icon_name = get_icon_name(pid, app_id, title)

    # Add icon using fuzzel's extended dmenu protocol: text\0icon\x1f<icon-name>
    entry_with_icon = f"{display_text}\0icon\x1f{icon_name}"

    return entry_with_icon


def select_with_fuzzel(entries):
    """Show fuzzel menu and return selected entry."""
    try:
        # Join entries with newlines, use -en for echo to preserve \0 and \x1f
        input_text = "\n".join(entries)

        result = subprocess.run(
            ["fuzzel", "--dmenu"],
            input=input_text.encode(),  # Send as bytes to preserve null bytes
            stdout=subprocess.PIPE,  # Capture stdout only, let stderr pass through
        )

        # fuzzel returns empty output if user cancels (Escape)
        if result.returncode != 0 or not result.stdout.strip():
            return None

        # Decode and return only the text part (before \0)
        output = result.stdout.decode().strip()
        # Fuzzel returns only the display text (before the first \0)
        return output.split("\0")[0] if "\0" in output else output
    except subprocess.CalledProcessError as e:
        print(f"Error running fuzzel: {e}", file=sys.stderr)
        sys.exit(1)


def find_window_by_display_text(windows, workspace_map, display_text):
    """Find the window that matches the selected display text."""
    # Parse the display text: [workspace_name] AppID - Title
    try:
        # Extract workspace, app_id, and title from the format
        parts = display_text.split("] ", 1)
        if len(parts) != 2:
            raise ValueError("Invalid format")

        workspace_display = parts[0].lstrip("[")

        rest = parts[1]
        app_title_parts = rest.split(" - ", 1)
        if len(app_title_parts) != 2:
            raise ValueError("Invalid format")

        app_id = app_title_parts[0]
        title = app_title_parts[1]

        # Find matching window
        for window in windows:
            w_app_id = window.get("app_id", "") or "window"
            w_title = window.get("title", "Untitled")
            w_workspace_id = window.get("workspace_id")

            # Get the workspace display name for this window
            w_workspace_display = workspace_map.get(w_workspace_id, str(w_workspace_id) if w_workspace_id else "?")

            if (w_app_id == app_id and
                w_title == title and
                w_workspace_display == workspace_display):
                return window["id"]

        raise ValueError("No matching window found")

    except (IndexError, ValueError) as e:
        print(f"Error finding window from '{display_text}': {e}", file=sys.stderr)
        sys.exit(1)


def focus_window(window_id):
    """Focus the window with the given ID."""
    try:
        subprocess.run(
            ["niri", "msg", "action", "focus-window", "--id", str(window_id)],
            check=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"Error focusing window {window_id}: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    # Get workspaces and windows
    workspace_map = get_workspaces()
    windows = get_windows()

    if not windows:
        print("No windows found", file=sys.stderr)
        sys.exit(1)

    # Sort windows: focused first, then by workspace, then by title
    windows.sort(key=lambda w: (
        not w.get("is_focused", False),
        w.get("workspace_id", 0),
        w.get("title", "").lower()
    ))

    # Format entries for fuzzel
    entries = [format_window_entry(w, workspace_map) for w in windows]

    # Show fuzzel and get selection
    selected = select_with_fuzzel(entries)

    if selected is None:
        # User cancelled
        sys.exit(0)

    # Find window ID and focus
    window_id = find_window_by_display_text(windows, workspace_map, selected)
    focus_window(window_id)


if __name__ == "__main__":
    main()
