#!/usr/bin/env python3
import argparse
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


ORG = "tur-pypi-dists"
TEMPLATE_REPO = "tur-pypi-dists/python-package-template"
WHEEL_DIR = Path("./output")


def run_cmd(
    args: list[str],
    *,
    capture_output: bool = False,
    check: bool = True,
) -> subprocess.CompletedProcess:
    return subprocess.run(
        args,
        check=check,
        text=True,
        capture_output=capture_output,
    )


def canonicalize_package_name(name: str) -> str:
    return re.sub(r"[-_.]+", "-", name).lower()


def wheel_sha256(wheel_path: Path) -> str:
    digest = hashlib.sha256()
    with wheel_path.open("rb") as fp:
        for chunk in iter(lambda: fp.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_wheel_fields(wheel_path: Path) -> tuple[str, str, str]:
    wheel_file = wheel_path.name
    if not wheel_file.endswith(".whl"):
        raise ValueError(f"Unsupported wheel file: {wheel_file}")

    wheel_base = wheel_file[:-4]
    parts = wheel_base.split("-")
    count = len(parts)
    if count < 5:
        raise ValueError(f"Unsupported wheel naming format: {wheel_file}")

    py_tag = parts[-3]
    head = parts[:-3]
    if len(head) < 2:
        raise ValueError(f"Unsupported wheel naming format: {wheel_file}")

    # Wheel format: distribution-version(-build)?-python_tag-abi_tag-platform_tag
    # Parse from the right to avoid mis-detecting version as build tag.
    if len(head) >= 3 and re.match(r"^[0-9][0-9A-Za-z_.]*$", head[-1]):
        name = "-".join(head[:-2])
        version = head[-2]
    else:
        name = "-".join(head[:-1])
        version = head[-1]

    if not name or not version:
        raise ValueError(f"Unsupported wheel naming format: {wheel_file}")

    pyversion = extract_pyversion_from_tag(py_tag)
    if not pyversion:
        raise ValueError(f"Unsupported python tag in wheel: {wheel_file}")

    return name, version, pyversion


def extract_pyversion_from_tag(py_tag: str) -> str:
    cp_versions: list[int] = []
    py_versions: list[int] = []

    for token in py_tag.split("."):
        cp_match = re.match(r"^cp([0-9]+)$", token)
        if cp_match:
            cp_versions.append(int(cp_match.group(1)))
            continue

        py_match = re.match(r"^py([0-9]+)$", token)
        if py_match:
            py_versions.append(int(py_match.group(1)))

    if cp_versions:
        return str(max(cp_versions))
    if py_versions:
        return str(max(py_versions))
    return ""


def py_digits_to_version(py_digits: str) -> str:
    if not re.match(r"^[0-9]+$", py_digits):
        raise ValueError(f"Invalid pyversion: {py_digits}")

    if len(py_digits) == 1:
        return py_digits

    major = py_digits[0]
    minor = int(py_digits[1:])
    return f"{major}.{minor}"


def ensure_repo_exists(full_repo: str) -> None:
    probe = run_cmd(["gh", "repo", "view", full_repo], check=False)
    if probe.returncode == 0:
        return

    print(f"Repository not found, creating from template: {full_repo}")
    run_cmd(["gh", "repo", "create", full_repo, "--template", TEMPLATE_REPO, "--public"])


def ensure_tag_exists(full_repo: str, tag: str) -> None:
    tag_probe = run_cmd(
        ["gh", "api", f"repos/{full_repo}/git/ref/tags/{tag}"],
        capture_output=True,
        check=False,
    )
    if tag_probe.returncode == 0:
        return

    head_ref = run_cmd(
        ["git", "ls-remote", f"https://github.com/{full_repo}.git", "HEAD"],
        capture_output=True,
    ).stdout.strip()
    if not head_ref:
        raise RuntimeError(f"Could not resolve HEAD for repository: {full_repo}")

    head_sha = head_ref.split()[0]
    print(f"Tag not found, creating tag {tag} for {full_repo}")
    run_cmd(
        [
            "gh",
            "api",
            "-X",
            "POST",
            f"repos/{full_repo}/git/refs",
            "-f",
            f"ref=refs/tags/{tag}",
            "-f",
            f"sha={head_sha}",
        ]
    )


def ensure_release_exists(full_repo: str, tag: str) -> None:
    repo_url = f"https://github.com/{full_repo}"
    probe = run_cmd(["gh", "release", "view", tag, "-R", repo_url], check=False)
    if probe.returncode == 0:
        return

    # Creating a release also creates the tag when it does not exist.
    run_cmd(
        [
            "gh",
            "release",
            "create",
            tag,
            "-R",
            repo_url,
            "--title",
            tag,
            "--notes",
            f"Automated wheel upload for {tag}",
        ]
    )


def upload_wheel(full_repo: str, tag: str, wheel_path: Path) -> None:
    repo_url = f"https://github.com/{full_repo}"
    run_cmd(["gh", "release", "upload", "--clobber", "-R", repo_url, tag, str(wheel_path)])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Upload wheel files and generate manifest records")
    parser.add_argument(
        "--manifest-out",
        default="",
        help="Write JSONL manifest records to this file path",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    wheels = sorted(WHEEL_DIR.glob("*.whl"))
    if not wheels:
        print(f"No wheel files found in {WHEEL_DIR}")
        return 0

    records: list[dict[str, str]] = []
    for wheel in wheels:
        name, version, pyversion = parse_wheel_fields(wheel)
        python_version = py_digits_to_version(pyversion)
        repo_name = f"python{python_version}-{name}"
        full_repo = f"{ORG}/{repo_name}"
        tag = f"v{version}"

        print(f"Processing {wheel} -> repo={full_repo} tag={tag} pyversion={pyversion}")
        ensure_repo_exists(full_repo)
        ensure_tag_exists(full_repo, tag)
        ensure_release_exists(full_repo, tag)
        upload_wheel(full_repo, tag, wheel)
        print(f"Uploaded {wheel} to {full_repo}:{tag}")

        filename = wheel.name
        records.append(
            {
                "package_name": name,
                "normalized_name": canonicalize_package_name(name),
                "version": version,
                "pyversion": pyversion,
                "python_version": python_version,
                "repo": full_repo,
                "tag": tag,
                "filename": filename,
                "url": f"https://github.com/{full_repo}/releases/download/{tag}/{filename}",
                "sha256": wheel_sha256(wheel),
                "uploaded_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            }
        )

    if args.manifest_out:
        out_path = Path(args.manifest_out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with out_path.open("w", encoding="utf-8") as fp:
            for row in records:
                fp.write(json.dumps(row, sort_keys=True, ensure_ascii=False) + "\n")
        print(f"Wrote {len(records)} wheel records to {out_path}")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        raise SystemExit(1)
