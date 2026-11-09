#!/usr/bin/env python3
"""nsw: build NixOS systems in one batch, then activate them one host at a time.

Replaces colmena. Hosts come from nsw.yaml next to the flake. The build goes
through iets (when on PATH) or nix, rendered by nom; activation runs
switch-to-configuration under systemd-run, locally via sudo or remotely over
ssh.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from collections import deque
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import yaml

ACTIONS = ("switch", "boot", "test", "dry-activate", "build")
DEFAULTS = {
    "user": "root",
    "build-on": "local",
    "substitute-on-destination": True,
    "copy-scheme": "ssh-ng",
    "diff": True,
    "ssh-opts": [],
}
HOST_KEYS = set(DEFAULTS) | {"target", "tags", "attr"}
CONFIG_KEYS = {"flake", "defaults", "hosts"}
PROFILE = "/nix/var/nix/profiles/system"
SYSTEMD_RUN = [
    "systemd-run",
    "-E",
    "LOCALE_ARCHIVE",
    "-E",
    "NIXOS_INSTALL_BOOTLOADER",
    "--collect",
    "--no-ask-password",
    "--pipe",
    "--quiet",
    "--same-dir",
    "--service-type=exec",
    "--unit=nsw-switch-to-configuration",
    "--wait",
]


# ---------------------------------------------------------------- terminal --

USE_COLOR = sys.stderr.isatty() and not os.environ.get("NO_COLOR")


def paint(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if USE_COLOR else s


def bold(s):
    return paint("1", s)


def dim(s):
    return paint("2", s)


def red(s):
    return paint("31", s)


def green(s):
    return paint("32", s)


def yellow(s):
    return paint("33", s)


def cyan(s):
    return paint("36", s)


def say(*parts: str):
    print(*parts, file=sys.stderr, flush=True)


def ok(msg: str):
    say(f"  {green('✓')} {msg}")


def bad(msg: str):
    say(f"  {red('✗')} {msg}")


def warn(msg: str):
    say(f"  {yellow('!')} {msg}")


def rule(title: str, right: str = ""):
    # a short fixed rule: a full-width one wraps badly when the window shrinks
    say("")
    say(f"── {title} " + dim("─" * 8) + (f"  {dim(right)}" if right else ""))


def fmt_elapsed(seconds: float) -> str:
    seconds = int(seconds)
    if seconds >= 60:
        return f"{seconds // 60}m{seconds % 60:02d}s"
    return f"{seconds}s"


def die(msg: str, code: int = 1):
    say(f"{red('error:')} {msg}")
    sys.exit(code)


def ask_continue(prompt: str) -> bool:
    if not sys.stdin.isatty():
        return False
    try:
        answer = input(f"  {yellow('?')} {prompt} [y/N] ")
    except EOFError:
        return False
    return answer.strip().lower() in ("y", "yes")


# -------------------------------------------------------------- processes --


def show_cmd(argv: list[str]):
    """Echo a command, dropping ssh's `-o key=value` boilerplate."""
    shown, skip = [], False
    for a in argv:
        if skip:
            skip = False
            continue
        if a == "-o":
            skip = True
            continue
        shown.append(a)
    say(dim("$ " + shlex.join(shown)))


def run(argv: list[str], **kw) -> subprocess.CompletedProcess:
    show_cmd(argv)
    return subprocess.run(argv, **kw)


# ------------------------------------------------------------------ config --


@dataclass
class Host:
    name: str
    target: Optional[str]
    user: str
    tags: list[str]
    build_on: str
    substitute: bool
    copy_scheme: str
    diff: bool
    ssh_opts: list[str]
    attr: str
    local: bool = False
    # filled in as the run proceeds
    out: Optional[str] = None
    status: str = "pending"
    note: str = ""

    @property
    def ssh_dest(self) -> str:
        return f"{self.user}@{self.target}"

    @property
    def builder_url(self) -> str:
        return f"ssh-ng://{self.ssh_dest}"

    def label(self, width: int = 0) -> str:
        """The name in colour, padded to `width` before the colour codes go on."""
        return bold(cyan(f"{self.name:<{width}}"))


@dataclass
class Config:
    path: Path
    flake: Path
    hosts: list[Host]
    defaults: dict
    flake_arg: str = field(init=False)

    def __post_init__(self):
        self.flake_arg = str(self.flake)

    def by_name(self, name: str) -> Host:
        for h in self.hosts:
            if h.name == name:
                return h
        die(
            f"no host {name!r} in {self.path}; known: {', '.join(h.name for h in self.hosts)}"
        )

    def select(self, specs: list[str], select_all: bool) -> list[Host]:
        if select_all:
            return list(self.hosts)
        if not specs:
            name = local_hostname()
            if not any(h.name == name for h in self.hosts):
                die(
                    f"this machine ({name}) is not in {self.path}; "
                    f"name a host or a @tag: {', '.join(h.name for h in self.hosts)}"
                )
            return [self.by_name(name)]
        chosen: list[Host] = []
        for spec in specs:
            if spec.startswith("@"):
                tagged = [h for h in self.hosts if spec[1:] in h.tags]
                if not tagged:
                    die(f"no host carries tag {spec}")
                chosen += tagged
            else:
                chosen.append(self.by_name(spec))
        # keep nsw.yaml order, drop duplicates
        return [h for h in self.hosts if h in chosen]


def local_hostname() -> str:
    try:
        return Path("/etc/hostname").read_text().strip()
    except OSError:
        return os.uname().nodename


def find_config(explicit: Optional[str]) -> Path:
    candidates = []
    if explicit:
        candidates.append(Path(explicit))
    if os.environ.get("NSW_CONFIG"):
        candidates.append(Path(os.environ["NSW_CONFIG"]))
    candidates.append(Path("nsw.yaml"))
    if os.environ.get("nixosConf"):
        candidates.append(Path(os.environ["nixosConf"]) / "nsw.yaml")
    candidates.append(Path("/etc/nixos/nsw.yaml"))
    for c in candidates:
        if c.is_file():
            return c.resolve()
    die("no nsw.yaml found (looked at: " + ", ".join(map(str, candidates)) + ")")


def load_config(path: Path) -> Config:
    with open(path) as f:
        raw = yaml.safe_load(f) or {}
    if not isinstance(raw, dict):
        die(f"{path}: top level must be a mapping")
    unknown = set(raw) - CONFIG_KEYS
    if unknown:
        die(f"{path}: unknown keys: {', '.join(sorted(unknown))}")
    defaults = {**DEFAULTS, **(raw.get("defaults") or {})}
    unknown = set(defaults) - set(DEFAULTS)
    if unknown:
        die(f"{path}: unknown keys under defaults: {', '.join(sorted(unknown))}")
    flake = (path.parent / (raw.get("flake") or ".")).resolve()
    if not (flake / "flake.nix").is_file():
        die(f"{path}: flake dir {flake} has no flake.nix")
    hosts_raw = raw.get("hosts") or {}
    if not hosts_raw:
        die(f"{path}: no hosts")
    me = local_hostname()
    hosts = []
    for name, entry in hosts_raw.items():
        entry = entry or {}
        unknown = set(entry) - HOST_KEYS
        if unknown:
            die(f"{path}: host {name}: unknown keys: {', '.join(sorted(unknown))}")
        v = {**defaults, **entry}
        if v["build-on"] not in ("local", "target"):
            die(f"{path}: host {name}: build-on must be local or target")
        if v["copy-scheme"] not in ("ssh", "ssh-ng"):
            die(f"{path}: host {name}: copy-scheme must be ssh or ssh-ng")
        target = entry.get("target")
        hosts.append(
            Host(
                name=name,
                target=target,
                user=v["user"],
                tags=list(v.get("tags") or []),
                build_on=v["build-on"],
                substitute=bool(v["substitute-on-destination"]),
                copy_scheme=v["copy-scheme"],
                diff=bool(v["diff"]),
                ssh_opts=list(v["ssh-opts"]),
                attr=v.get("attr")
                or f"nixosConfigurations.{name}.config.system.build.toplevel",
                local=target is None or name == me,
            )
        )
    return Config(path=path, flake=flake, hosts=hosts, defaults=defaults)


# --------------------------------------------------------------------- ssh --


class Ssh:
    """ssh with one multiplexed connection per host for the whole run."""

    def __init__(self, tmp: Path):
        self.control = str(tmp / "ssh-%C")
        self.opened: list[Host] = []

    def opts(self, host: Host) -> list[str]:
        return [
            "-o",
            "ControlMaster=auto",
            "-o",
            f"ControlPath={self.control}",
            "-o",
            "ControlPersist=120",
            *host.ssh_opts,
        ]

    def argv(self, host: Host, remote: list[str]) -> list[str]:
        return ["ssh", *self.opts(host), host.ssh_dest, "--", shlex.join(remote)]

    def shell(self, host: Host, script: str) -> list[str]:
        """Like argv, but `script` is handed to the remote shell verbatim."""
        return ["ssh", *self.opts(host), host.ssh_dest, "--", script]

    def run(self, host: Host, remote: list[str], **kw) -> subprocess.CompletedProcess:
        if host not in self.opened:
            self.opened.append(host)
        return run(self.argv(host, remote), **kw)

    def env(self, host: Host) -> dict[str, str]:
        """Environment that makes `nix copy` use the same multiplexed connection."""
        if host not in self.opened:
            self.opened.append(host)
        return {**os.environ, "NIX_SSHOPTS": shlex.join(self.opts(host))}

    def close_all(self):
        for host in self.opened:
            subprocess.run(
                [
                    "ssh",
                    "-o",
                    f"ControlPath={self.control}",
                    "-O",
                    "exit",
                    host.ssh_dest,
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )


# ------------------------------------------------------------------- build --


def with_nom(
    argv: list[str], use_nom: bool, **kw
) -> tuple[subprocess.CompletedProcess, bytes]:
    """Run a nix-like command whose stderr is internal-json, rendering it with nom.

    Returns the process result and what it wrote to stdout. nom owns the
    terminal until the command finishes, so nothing else is printed meanwhile.
    """
    if use_nom:
        show_cmd(argv + ["|&", "nom", "--json"])
        proc = subprocess.Popen(
            argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kw
        )
        nom = subprocess.Popen(["nom", "--json"], stdin=proc.stderr)
        proc.stderr.close()  # nom holds the only reference now
        out = proc.stdout.read()
        proc.wait()
        nom.wait()
    else:
        show_cmd(argv)
        proc = subprocess.Popen(argv, stdout=subprocess.PIPE, **kw)
        out = proc.stdout.read()
        proc.wait()
    return subprocess.CompletedProcess(argv, proc.returncode), out


def pick_output(outputs) -> Optional[str]:
    """The `out` path from whatever shape the JSON gives: dict, list, or string."""
    if isinstance(outputs, str):
        return outputs
    if isinstance(outputs, dict):
        if "out" in outputs:
            return outputs["out"]
        return next(iter(outputs.values()), None)
    if isinstance(outputs, list) and outputs:
        first = outputs[0]
        return (
            first if isinstance(first, str) else first.get("path") or first.get("out")
        )
    return None


_missing_warned: set[str] = set()


def tool_present(name: str, fallback: str) -> bool:
    """Whether `name` is on PATH; warns once per run about the fallback if not."""
    if shutil.which(name) is not None:
        return True
    if name not in _missing_warned:
        _missing_warned.add(name)
        warn(f"{name} not on PATH, {fallback}")
    return False


def build_group(cfg: Config, hosts: list[Host], builder: Optional[Host], opts) -> None:
    """Build every host's toplevel in one evaluator run; record each host's outcome."""
    roots = [f"{cfg.flake_arg}#{h.attr}" for h in hosts]
    use_iets = opts.iets and tool_present("iets", "building with plain nix build")
    use_nom = opts.nom and tool_present("nom", "showing raw nix logs")
    out_link = str(opts.tmp / f"result-{builder.name if builder else 'local'}")

    if use_iets:
        argv = ["iets", "build", *roots, "--json"]
        if use_nom:
            argv += ["--log-format", "internal-json"]
        if builder:
            argv += ["--builder", builder.builder_url]
        else:
            argv += ["--out-link", out_link]
    else:
        argv = [
            "nix",
            "build",
            *roots,
            "--json",
            "--keep-going",
            "--out-link",
            out_link,
        ]
        if use_nom:
            argv += ["--log-format", "internal-json", "-v"]
        if builder:
            argv += ["--builders", builder.builder_url, "--max-jobs", "0"]
    if opts.show_trace:
        argv.append("--show-trace")
    argv += opts.build_args

    env = dict(os.environ)
    if builder:
        env["NIX_SSHOPTS"] = shlex.join(opts.ssh.opts(builder))
    started = time.monotonic()
    res, out = with_nom(argv, use_nom, env=env, cwd=cfg.flake)
    elapsed = fmt_elapsed(time.monotonic() - started)

    try:
        data = json.loads(out) if out.strip() else None
    except json.JSONDecodeError:
        data = None

    if use_iets:
        outcomes = (data or {}).get("outcomes") or []
        for i, h in enumerate(hosts):
            o = next(
                (o for o in outcomes if str(o.get("attr", "")).endswith(h.attr)), None
            )
            if o is None and i < len(outcomes):
                o = outcomes[i]
            if o and o.get("success") and pick_output(o.get("outputs")):
                h.out = pick_output(o["outputs"])
                h.status = "built"
            else:
                h.status = "failed"
                h.note = "build failed" + (
                    f": {o['reason']}" if o and o.get("reason") else ""
                )
                if o and o.get("logTail"):
                    tail = (
                        o["logTail"]
                        if isinstance(o["logTail"], str)
                        else "\n".join(o["logTail"])
                    )
                    h.note += "\n" + tail
    else:
        results = data if isinstance(data, list) else []
        for i, h in enumerate(hosts):
            path = pick_output(results[i].get("outputs")) if i < len(results) else None
            if res.returncode == 0 and path:
                h.out, h.status = path, "built"
            elif path and Path(path).exists():
                h.out, h.status = path, "built"
            else:
                h.status, h.note = "failed", "build failed"

    built = [h for h in hosts if h.status == "built"]
    failed = [h for h in hosts if h.status == "failed"]
    if failed:
        bad(
            f"{len(failed)} failed: {', '.join(h.name for h in failed)}  {dim(elapsed)}"
        )
        for h in failed:
            say(dim(f"    {h.name}: {h.note.splitlines()[0]}"))
            for line in h.note.splitlines()[1:]:
                say(dim("      " + line))
        if res.returncode != 0 and not out.strip():
            say(dim(f"    (exit {res.returncode}, no JSON on stdout)"))
    if built:
        ok(f"{len(built)} built  {dim(elapsed)}")


# ---------------------------------------------------------------- activate --


def remote_closure_cmd(host: Host, path: str) -> list[str]:
    return ["nix", "store", "diff-closures", "/run/current-system", path]


def activation_cmds(host: Host, action: str) -> list[list[str]]:
    cmds: list[list[str]] = []
    if action in ("switch", "boot"):
        cmds.append(["nix-env", "-p", PROFILE, "--set", host.out])
    cmds.append([*SYSTEMD_RUN, f"{host.out}/bin/switch-to-configuration", action])
    return cmds


def current_generation(host: Host, ssh: Ssh) -> str:
    argv = ["readlink", PROFILE]
    if host.local:
        res = subprocess.run(argv, capture_output=True, text=True)
    else:
        res = subprocess.run(ssh.argv(host, argv), capture_output=True, text=True)
    m = re.search(r"system-(\d+)-link", res.stdout)
    return m.group(1) if m else ""


def done_message(action: str, gen: str, elapsed: str) -> str:
    where = f"generation {gen}" if gen else "the new configuration"
    return {
        "switch": f"switched to {where} in {elapsed}",
        "boot": f"{where} set for next boot in {elapsed}",
        "test": f"tested in {elapsed}",
        "dry-activate": f"dry-activated in {elapsed}",
    }.get(action, f"{action} done in {elapsed}")


def copy_argv(host: Host) -> list[str]:
    # the target's daemon would otherwise reject the unsigned local build; the
    # ssh user is root, so it may waive the check (`nix-store --serve` never checks)
    argv = [
        "nix",
        "copy",
        "--no-check-sigs",
        "--to",
        f"{host.copy_scheme}://{host.ssh_dest}?compress=true",
    ]
    if host.substitute:
        argv.append("--substitute-on-destination")
    argv.append(host.out)
    return argv


def copy_host(host: Host, opts) -> None:
    """Push one closure with nix's own progress output. Sets host.status on failure."""
    ssh: Ssh = opts.ssh
    started = time.monotonic()
    res = run(copy_argv(host), env=ssh.env(host))
    if res.returncode != 0:
        host.status, host.note = "failed", f"nix copy exit {res.returncode}"
        bad(f"{host.name}: {host.note}")
        return
    ok(f"{host.name} copied  {dim(fmt_elapsed(time.monotonic() - started))}")


# nix's internal-json vocabulary (src/libutil/logging.hh)
ACT_COPY_PATH = 100
RES_PROGRESS = 105
RES_SET_EXPECTED = 106


class CopyProgress:
    """What one `nix copy --log-format internal-json` has reported so far."""

    def __init__(self):
        self.paths = [0, 0]  # done, expected
        self.bytes_total = 0
        self.per_path: dict[int, list[int]] = {}  # activity id -> [done, expected]
        self.messages: list[str] = []
        self.rc: Optional[int] = None
        self.started = time.monotonic()
        self.elapsed = 0.0
        self.samples: deque[tuple[float, int]] = deque(maxlen=20)  # ~3s window

    @property
    def bytes_done(self) -> int:
        return sum(d for d, _ in self.per_path.values())

    def speed(self) -> Optional[float]:
        """Bytes per second over the recent samples; None until there are enough."""
        self.samples.append((time.monotonic(), self.bytes_done))
        (t0, b0), (t1, b1) = self.samples[0], self.samples[-1]
        if t1 - t0 < 0.5:
            return None
        return (b1 - b0) / (t1 - t0)

    def feed(self, raw: bytes) -> None:
        if not raw.startswith(b"@nix "):
            text = raw.decode(errors="replace").rstrip()
            if text:
                self.messages.append(text)
            return
        try:
            d = json.loads(raw[5:])
        except ValueError:
            return
        action, ident = d.get("action"), d.get("id")
        if action == "start" and d.get("type") == ACT_COPY_PATH:
            self.per_path[ident] = [0, 0]
        elif action == "result":
            f = d.get("fields") or []
            if d.get("type") == RES_PROGRESS and len(f) >= 2:
                if ident in self.per_path:
                    self.per_path[ident] = [f[0], f[1]]
                else:  # the aggregate: done, expected, running, failed paths
                    self.paths = [f[0], f[1]]
            elif d.get("type") == RES_SET_EXPECTED and len(f) >= 2:
                if f[0] == ACT_COPY_PATH:
                    self.bytes_total = max(self.bytes_total, f[1])
        elif action == "stop" and ident in self.per_path:
            done, expected = self.per_path[ident]
            self.per_path[ident] = [max(done, expected), expected]
        elif action == "msg" and d.get("level", 9) <= 1:  # error, warn
            if d.get("text"):
                self.messages.append(d["text"])


def fmt_bytes(n: int) -> str:
    mib = n / (1 << 20)
    if mib >= 1024:
        return f"{mib / 1024:.2f} GiB"
    if mib < 1:
        return f"{n / 1024:.0f} KiB"
    return f"{mib:.1f} MiB"


def copy_line(host: Host, prog: CopyProgress, width: int) -> str:
    """One status line; a bar while running, a verdict once done."""
    label = host.label(width)
    if prog.rc is None:
        done, total = prog.bytes_done, max(prog.bytes_total, prog.bytes_done)
        frac = done / total if total else 0.0
        filled = int(frac * 20)
        bar = cyan("━" * filled) + dim("━" * (20 - filled))
        paths = f"{prog.paths[0]}/{prog.paths[1]} paths" if prog.paths[1] else ""
        size = f"{fmt_bytes(done)}/{fmt_bytes(total)}" if total else ""
        rate = prog.speed()
        speed = dim(f"{fmt_bytes(int(rate))}/s") if rate is not None else ""
        return f"  {label}  {bar}  {paths:<14} {size:<20} {speed}"
    stats = dim(
        f"{prog.paths[1]} paths, {fmt_bytes(prog.bytes_total)}, {fmt_elapsed(prog.elapsed)}"
    )
    if prog.rc == 0:
        return f"  {green('✓')} {label} copied  {stats}"
    return f"  {red('✗')} {label} nix copy exit {prog.rc}  {stats}"


def copy_hosts(hosts: list[Host], opts) -> None:
    """Push every closure at once; one live line per host instead of N progress bars."""
    ssh: Ssh = opts.ssh
    width = max(len(h.name) for h in hosts)
    progress = {h.name: CopyProgress() for h in hosts}
    procs = {}
    for h in hosts:
        argv = copy_argv(h)
        show_cmd(argv)
        procs[h.name] = subprocess.Popen(
            [*argv, "--log-format", "internal-json"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            env=ssh.env(h),
        )

    def pump(name: str) -> None:
        proc, prog = procs[name], progress[name]
        for raw in proc.stderr:
            prog.feed(raw)
        prog.rc = proc.wait()
        prog.elapsed = time.monotonic() - prog.started

    threads = [
        threading.Thread(target=pump, args=(h.name,), daemon=True) for h in hosts
    ]
    for t in threads:
        t.start()

    live = sys.stderr.isatty()

    def render() -> None:
        for h in hosts:
            say(copy_line(h, progress[h.name], width))

    if live:
        sys.stderr.write("\x1b[?25l")  # hide the cursor while redrawing
        render()
    try:
        while any(t.is_alive() for t in threads):
            for t in threads:
                t.join(0.15)
            if live:
                sys.stderr.write(f"\x1b[{len(hosts)}A")
                for h in hosts:
                    sys.stderr.write("\x1b[2K")
                    say(copy_line(h, progress[h.name], width))
        if not live:
            render()
    finally:
        if live:
            sys.stderr.write("\x1b[?25h")
            sys.stderr.flush()

    for h in hosts:
        prog = progress[h.name]
        if prog.rc != 0:
            h.status, h.note = "failed", f"nix copy exit {prog.rc}"
            for line in prog.messages[-8:]:
                say(dim("      " + line))


def activate_host(host: Host, opts, index: int, total: int) -> None:
    """Optionally diff, then activate one host whose closure is in place."""
    where = "local" if host.local else host.ssh_dest
    rule(f"activating {host.label()}  {dim(where)}", f"{index}/{total}")
    ssh: Ssh = opts.ssh

    if host.diff:
        argv = remote_closure_cmd(host, host.out)
        res = run(argv) if host.local else ssh.run(host, argv)
        if res.returncode != 0:
            warn(f"diff-closures exit {res.returncode}, going on")

    if opts.dry_run:
        ok("built and copied, not activated")
        return

    if host.local:
        res = run(["sudo", "-v"])
        if res.returncode != 0:
            host.status, host.note = "failed", "sudo refused"
            bad(host.note)
            return
    started = time.monotonic()
    for cmd in activation_cmds(host, opts.action):
        if host.local:
            res = run(["sudo", "--preserve-env=NIXOS_INSTALL_BOOTLOADER", "--", *cmd])
        else:
            res = ssh.run(host, cmd)
        if res.returncode != 0:
            host.status, host.note = "failed", f"{cmd[0]} exit {res.returncode}"
            if cmd[0] == "systemd-run":
                host.note = f"switch-to-configuration exit {res.returncode}"
            bad(host.note)
            return
    host.status = opts.action
    gen = current_generation(host, ssh) if opts.action in ("switch", "boot") else ""
    host.note = f"gen {gen}" if gen else ""
    ok(done_message(opts.action, gen, fmt_elapsed(time.monotonic() - started)))


HOME_ACTIONS = ("switch", "dry-activate", "build")


def home_generation() -> str:
    """Number of the current home-manager generation, "" if there is none."""
    user = os.environ.get("USER", "")
    for link in (
        Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
        / "nix/profiles/home-manager",
        Path(f"/nix/var/nix/profiles/per-user/{user}/home-manager"),
    ):
        m = re.search(
            r"home-manager-(\d+)-link", os.readlink(link) if link.is_symlink() else ""
        )
        if m:
            return m.group(1)
    return ""


def activate_home(host: Host, opts) -> None:
    """Run the activation script of a built homeConfigurations.<name> here."""
    rule(f"activating {host.label()}  {dim('home-manager')}", "1/1")
    current = Path.home() / ".local/state/home-manager/gcroots/current-home"
    if host.diff and current.exists():
        res = run(["nix", "store", "diff-closures", str(current), host.out])
        if res.returncode != 0:
            warn(f"diff-closures exit {res.returncode}, going on")
    if opts.dry_run:
        ok("built, not activated")
        return

    started = time.monotonic()
    env = dict(os.environ)
    if opts.action == "dry-activate":
        env["DRY_RUN"] = "1"
    res = run([f"{host.out}/activate"], env=env)
    if res.returncode != 0:
        host.status, host.note = "failed", f"activate exit {res.returncode}"
        bad(host.note)
        return
    host.status = opts.action
    gen = home_generation() if opts.action == "switch" else ""
    host.note = f"gen {gen}" if gen else ""
    ok(done_message(opts.action, gen, fmt_elapsed(time.monotonic() - started)))


# -------------------------------------------------------------------- exec --


def local_shell_argv(host: Host, script: str) -> list[str]:
    """`sh -c script` as the host's configured user, through sudo when that is not us."""
    argv = ["sh", "-c", script]
    if host.user != os.environ.get("USER", ""):
        argv = ["sudo", "-u", host.user, "--", *argv]
    return argv


def exec_main(cfg: Config, hosts: list[Host], opts) -> int:
    """`nsw --batch-exec CMD`: run one shell command on each selected host, nothing else."""
    script: str = opts.batch_exec
    others = [h.name for h in cfg.hosts if h not in hosts]
    say(
        f"{bold('nsw')} ▸ exec  {', '.join(h.name for h in hosts)}"
        + (dim(f"   ({', '.join(others)} not selected)") if others else "")
    )
    opts.tmp = Path(tempfile.mkdtemp(prefix="nsw."))
    opts.ssh = Ssh(opts.tmp)
    try:
        for i, h in enumerate(hosts, 1):
            where = "local" if h.local else h.ssh_dest
            rule(f"{h.label()}  {dim(where)}", f"{i}/{len(hosts)}")
            if h.local:
                argv = local_shell_argv(h, script)
            else:
                argv = opts.ssh.shell(h, script)
                opts.ssh.opened.append(h)
            res = run(argv)
            if res.returncode == 0:
                h.status = "done"
            else:
                h.status, h.note = "failed", f"exit {res.returncode}"
                bad(h.note)
        summary(hosts)
        return 0 if all(h.status == "done" for h in hosts) else 1
    except KeyboardInterrupt:
        say("")
        warn("interrupted")
        return 130
    finally:
        opts.ssh.close_all()
        shutil.rmtree(opts.tmp, ignore_errors=True)


# ---------------------------------------------------------------------- cli --


def parse_args(argv: list[str]):
    build_args: list[str] = []
    if "--" in argv:
        i = argv.index("--")
        argv, build_args = argv[:i], argv[i + 1 :]

    p = argparse.ArgumentParser(
        prog="nsw",
        description="build NixOS systems in one batch, then activate them one by one",
        epilog="everything after `--` is passed to `iets build` / `nix build` verbatim",
    )
    p.add_argument(
        "hosts", nargs="*", metavar="HOST|@TAG", help="default: this machine"
    )
    p.add_argument("--all", action="store_true", help="every host in nsw.yaml")
    p.add_argument(
        "--home",
        metavar="NAME",
        help="instead of hosts: build homeConfigurations.NAME and activate it here, "
        "like `home-manager switch --flake .#NAME` (actions: switch, dry-activate, build)",
    )
    p.add_argument(
        "--batch-exec",
        metavar="CMD",
        help="instead of building: run the shell command CMD on each selected host "
        "(over ssh, or locally as the host's user) and nothing else",
    )
    p.add_argument("-l", "--list", action="store_true", help="list hosts and exit")
    p.add_argument("-a", "--action", choices=ACTIONS, default="switch")
    p.add_argument(
        "-n", "--dry-run", action="store_true", help="build and copy, activate nothing"
    )
    p.add_argument(
        "--build-on", choices=("local", "target"), help="override for every host"
    )
    sub = p.add_mutually_exclusive_group()
    sub.add_argument(
        "--substitute-on-destination",
        dest="substitute",
        action="store_true",
        default=None,
    )
    sub.add_argument(
        "--no-substitute-on-destination", dest="substitute", action="store_false"
    )
    p.add_argument("--show-trace", action="store_true")
    diff = p.add_mutually_exclusive_group()
    diff.add_argument(
        "--diff",
        dest="diff",
        action="store_true",
        default=None,
        help="show `nix store diff-closures` before activating (default)",
    )
    diff.add_argument(
        "--no-diff", dest="diff", action="store_false", help="skip the closure diff"
    )
    p.add_argument(
        "--no-iets", dest="iets", action="store_false", help="build with nix, not iets"
    )
    p.add_argument(
        "--no-nom",
        dest="nom",
        action="store_false",
        help="raw nix logs; closures are then copied one host at a time",
    )
    p.add_argument(
        "-k", "--keep-going", action="store_true", help="go on after a host fails"
    )
    p.add_argument(
        "-c",
        "--config",
        metavar="PATH",
        help="nsw.yaml (default: ./nsw.yaml, $NSW_CONFIG, $nixosConf/, /etc/nixos/)",
    )
    opts = p.parse_args(argv)
    opts.build_args = build_args
    if os.environ.get("NSW_NO_IETS"):
        opts.iets = False
    return opts


def list_hosts(cfg: Config):
    say(f"{dim('config')} {cfg.path}   {dim('flake')} {cfg.flake}")
    for h in cfg.hosts:
        where = "local" if h.local else h.ssh_dest
        tags = " ".join("@" + t for t in h.tags)
        extra = "  build-on target" if h.build_on == "target" else ""
        say(f"  {h.label(16)} {where:<28} {dim(tags)}{dim(extra)}")


def summary(hosts: list[Host]):
    rule("summary")
    icons = {
        "switch": green("✓"),
        "boot": green("✓"),
        "test": green("✓"),
        "dry-activate": green("✓"),
        "built": green("✓"),
        "done": green("✓"),
        "failed": red("✗"),
        "skipped": yellow("–"),
        "pending": yellow("–"),
    }
    words = {
        "switch": "switched",
        "boot": "boot",
        "test": "tested",
        "pending": "skipped",
    }
    for h in hosts:
        status = words.get(h.status, h.status)
        note = h.note.splitlines()[0] if h.note else ""
        say(f"  {h.label(16)} {icons[h.status]} {status:<12} {dim(note)}")


def home_main(cfg: Config, opts) -> int:
    """`nsw --home NAME`: one local home-manager profile, no hosts involved."""
    if opts.hosts or opts.all:
        die("--home takes no hosts")
    if opts.action not in HOME_ACTIONS:
        die(f"--home supports -a {', '.join(HOME_ACTIONS)}, not {opts.action}")
    if opts.build_on == "target":
        die("--home always builds locally")
    d = cfg.defaults
    home = Host(
        name=opts.home,
        target=None,
        user=os.environ.get("USER", ""),
        tags=[],
        build_on="local",
        substitute=False,
        copy_scheme=d["copy-scheme"],
        diff=d["diff"] if opts.diff is None else opts.diff,
        ssh_opts=[],
        attr=f"homeConfigurations.{opts.home}.activationPackage",
        local=True,
    )
    say(f"{bold('nsw')} ▸ {opts.action}  {dim('home')} {home.name}")
    opts.tmp = Path(tempfile.mkdtemp(prefix="nsw."))
    opts.ssh = Ssh(opts.tmp)
    try:
        rule("build")
        build_group(cfg, [home], None, opts)
        if opts.action == "build":
            if home.out:
                print(home.out)
        elif home.status == "built":
            activate_home(home, opts)
        summary([home])
        good = {"built"} if opts.dry_run or opts.action == "build" else {opts.action}
        return 0 if home.status in good else 1
    except KeyboardInterrupt:
        say("")
        warn("interrupted")
        return 130
    finally:
        shutil.rmtree(opts.tmp, ignore_errors=True)


def main() -> int:
    opts = parse_args(sys.argv[1:])
    cfg = load_config(find_config(opts.config))
    if opts.list:
        list_hosts(cfg)
        return 0

    if opts.home:
        if opts.batch_exec:
            die("--batch-exec and --home do not mix")
        return home_main(cfg, opts)

    hosts = cfg.select(opts.hosts, opts.all)
    if opts.batch_exec:
        return exec_main(cfg, hosts, opts)
    for h in hosts:
        if opts.build_on:
            h.build_on = opts.build_on
        if h.local:
            h.build_on = "local"
        if opts.substitute is not None:
            h.substitute = opts.substitute
        if opts.diff is not None:
            h.diff = opts.diff

    others = [h.name for h in cfg.hosts if h not in hosts]
    say(
        f"{bold('nsw')} ▸ {opts.action}  {', '.join(h.name for h in hosts)}"
        + (dim(f"   ({', '.join(others)} not selected)") if others else "")
    )

    opts.tmp = Path(tempfile.mkdtemp(prefix="nsw."))
    opts.ssh = Ssh(opts.tmp)
    try:
        rule("build")
        groups: dict[Optional[str], list[Host]] = {}
        for h in hosts:
            if h.status != "pending":
                continue
            key = h.name if h.build_on == "target" else None
            groups.setdefault(key, []).append(h)
        for key, group in groups.items():
            builder = cfg.by_name(key) if key else None
            if builder:
                say(dim(f"  building on {builder.ssh_dest}"))
            build_group(cfg, group, builder, opts)

        if opts.action == "build":
            for h in hosts:
                if h.out:
                    print(h.out)
            summary(hosts)
            return 0 if all(h.status == "built" for h in hosts) else 1

        # copy every closure first: copies are independent and the slow part,
        # so a host that cannot be reached fails before anything is activated
        to_copy = [
            h
            for h in hosts
            if h.status == "built" and not h.local and h.build_on != "target"
        ]
        if to_copy:
            rule("copy")
            if opts.nom:
                copy_hosts(to_copy, opts)
            else:
                for h in to_copy:
                    copy_host(h, opts)

        todo = [h for h in hosts if h.status == "built"]
        stop = False
        for i, h in enumerate(todo, 1):
            if stop:
                h.status = "skipped"
                continue
            activate_host(h, opts, i, len(todo))
            remaining = todo[i:]
            if h.status == "failed" and remaining and not opts.keep_going:
                if not ask_continue(
                    f"continue with {', '.join(r.name for r in remaining)}?"
                ):
                    stop = True
        summary(hosts)
        good = {"built"} if opts.dry_run else {opts.action}
        return 0 if all(h.status in good for h in hosts) else 1
    except KeyboardInterrupt:
        say("")
        warn("interrupted; a switch already started on a host keeps running there")
        return 130
    finally:
        opts.ssh.close_all()
        shutil.rmtree(opts.tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
