#!/usr/bin/env python3
# audit-and-repair-wheel.py - Audit and repair a wheel.
#
# This file is a rewrite of the origin auditwheel. It doesn't
# work out-of-box for termux.
#
# Origin file: https://github.com/pypa/auditwheel/blob/99e5367c1a3fa22afd2e7c64f09fb912cca6e27a/src/auditwheel/main_repair.py
#
from __future__ import annotations


from typing import Iterable
import argparse
import logging
from itertools import chain
from os.path import abspath, basename, exists, isfile
import os
from subprocess import check_call, check_output

import auditwheel.repair
import auditwheel.lddtree
from auditwheel.patcher import Patchelf
from auditwheel.repair import repair_wheel

TERMUX_LIB_DIR = "/data/data/com.termux/files/usr/lib"

TERMUX_EXCLUDE_LIBRARIES = [
    # System provided libraries
    "libc.so", "libdl.so", "libm.so", "liblog.so",
    # C++ runtime library
    "libc++_shared.so",
    # Termux essentials
    "libandroid-support.so", "libtermux-exec.so", "libiconv.so",
    "libexpat.so.1", "libz.so.1", "liblzma.so.5", "libbz2.so.1.0",
    "libssl.so.3", "libcrypto.so.3", 
    "libcurl.so", "libnghttp2.so", "libnghttp3.so", "libssh2.so",
    # libpython* libraries
    "libpython3.so",
    "libpython3.7m.so.1.0", "libpython3.8.so.1.0", "libpython3.9.so.1.0",
    "libpython3.10.so.1.0", "libpython3.11.so.1.0", "libpython3.12.so.1.0",
    # TODO: Python package dependencies
    # TODO: X related libraries
    "libX11.so", "libX11.so.6", "libXext.so", "libXrender.so", "libICE.so",
    "libSM.so", "libGL.so", "libxcb.so", 
]

# Hook strip_symbols
def strip_symbols(libraries: Iterable[str]) -> None:
    # Make sure that we will not strip for Android.
    os.abort()

# Hook load_ld_paths
def load_ld_paths(root: str = "/", prefix: str = "") -> dict[str, list[str]]:
    return {"conf": [TERMUX_LIB_DIR], "env": [], "interp": []}

auditwheel.repair.strip_symbols = strip_symbols
auditwheel.lddtree.load_ld_paths = load_ld_paths

class TermuxPatchelf(Patchelf):
    def set_rpath(self, file_name: str, rpath: str) -> None:
        rpathes = rpath.split(":")
        # https://github.com/pypa/auditwheel/issues/344
        # https://github.com/pypa/auditwheel/pull/454
        for i in range(len(rpathes)):
            rpath_ = rpathes[i]
            if not rpath_.startswith("/") and not rpath_.startswith("$ORIGIN"):
                rpathes[i] = os.path.join("$ORIGIN", os.path.relpath(rpath_, os.path.dirname(file_name)))
        # No matter what, add TERMUX_LIB_DIR
        rpathes.append(TERMUX_LIB_DIR)
        rpath = ":".join(rpathes)
        check_call(["patchelf", "--remove-rpath", file_name])
        check_call(["patchelf", "--set-rpath", rpath, file_name])

logger = logging.getLogger(__name__)

def configure_parser(p):
    p.add_argument(
        "-L",
        "--lib-sdir",
        dest="LIB_SDIR",
        help=(
            "Subdirectory in packages to store copied libraries." ' (default: ".libs")'
        ),
        default=".libs",
    )
    p.add_argument(
        "-w",
        "--wheel-dir",
        dest="WHEEL_DIR",
        type=abspath,
        help=("Directory to store delocated wheels (default:" ' "wheelhouse/")'),
        default="wheelhouse/",
    )
    p.add_argument(
        "--no-update-tags",
        dest="UPDATE_TAGS",
        action="store_false",
        help=(
            "Do not update the wheel filename tags and WHEEL info"
            " to match the repaired platform tag."
        ),
        default=True,
    )
    p.add_argument(
        "--exclude",
        dest="EXCLUDE",
        help="Exclude SONAME from grafting into the resulting wheel "
        "(can be specified multiple times)",
        action="append",
        default=[],
    )
    p.add_argument("WHEEL_FILE", help="Path to wheel file.", nargs="+")
    p.set_defaults(func=execute)


def execute(args, p):
    for wheel_file in args.WHEEL_FILE:
        if not isfile(wheel_file):
            p.error("cannot access %s. No such file" % wheel_file)

        logger.info("Repairing %s", basename(wheel_file))

        if not exists(args.WHEEL_DIR):
            os.makedirs(args.WHEEL_DIR)

        patcher = TermuxPatchelf()
        out_wheel = repair_wheel(
            wheel_path=wheel_file,
            abis=["linux_x86_64"],
            lib_sdir=args.LIB_SDIR,
            out_dir=args.WHEEL_DIR,
            update_tags=args.UPDATE_TAGS,
            patcher=patcher,
            exclude=args.EXCLUDE + TERMUX_EXCLUDE_LIBRARIES,
            strip=False,
        )

        if out_wheel is not None:
            logger.info("\nFixed-up wheel written to %s", out_wheel)


def main():
    p = argparse.ArgumentParser(description="Cross-distro Python wheels.")
    p.add_argument(
        "-v",
        "--verbose",
        action="count",
        dest="verbose",
        default=0,
        help="Give more output. Option is additive",
    )
    configure_parser(p)
    args = p.parse_args()
    logging.disable(logging.NOTSET)
    if args.verbose >= 1:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)
    args.func(args, p)


if __name__ == '__main__':
    main()
