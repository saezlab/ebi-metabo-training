"""Shared helpers for the Python training scripts."""

from __future__ import annotations

from pathlib import Path


def repo_root() -> Path:
    here = Path(__file__).resolve().parent if "__file__" in globals() else Path.cwd()
    for candidate in [here, *here.parents]:
        if (candidate / "env" / "pyproject.toml").exists():
            return candidate
    return Path.cwd()


def results_dir(subdir: str | None = None) -> Path:
    out = repo_root() / "results"
    if subdir is not None:
        out = out / subdir
    out.mkdir(parents=True, exist_ok=True)
    return out
