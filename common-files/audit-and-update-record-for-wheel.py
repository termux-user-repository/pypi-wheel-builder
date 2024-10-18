#!/usr/bin/env python3
# audit-and-update-record-for-wheel.py - Check the lib and license for wheels, and update RECORD file for wheels.
#
from __future__ import annotations

import argparse
import logging
from os.path import abspath, basename, exists, isfile
import os
import json

from auditwheel.wheeltools import InWheelCtx

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
        "WHEEL_FILE", 
        type=str,
        help="Path to wheel file.",
    )
    p.add_argument(
        "-j",
        "--json",
        dest="LICENSE_JSON",
        help="Path to lib-license json.",
    )
    p.add_argument(
        "-nolib",
        "--ensure-no-libs",
        dest="NO_LIBS",
        action="store_true",
        help="Ensure there is no libs.",
        default=False,
    )
    p.add_argument(
        "-clib",
        "--check-libs",
        dest="CHECK_LIBS",
        action="store_true",
        help=(
            "Enable checking libs."
        ),
        default=False,
    )
    p.add_argument(
        "-clic",
        "--check-licenses",
        dest="CHECK_LICENSES",
        action="store_true",
        help=(
            "Enable checking licenses."
        ),
        default=False,
    )
    p.set_defaults(func=execute)


def parse_license_json(filepath):
    libs = set()
    licenses = {}
    with open(filepath, "r") as fp:
        for e in json.load(fp):
            for lib in e["libs"]:
                libs.add(lib)
            for license in e["licenses"]:
                licenses[license] = False
    return libs, licenses


def execute(args, p):
    wheel_file = args.WHEEL_FILE
    if not isfile(wheel_file):
        logger.error("cannot access %s. No such file" % wheel_file)
        exit(1)

    if not exists(args.WHEEL_DIR):
        os.makedirs(args.WHEEL_DIR)

    out_wheel=os.path.join(args.WHEEL_DIR, basename(wheel_file))
    with InWheelCtx(in_wheel=wheel_file, out_wheel=out_wheel) as ctx:
        if not args.CHECK_LIBS and not args.CHECK_LICENSES:
            logger.info("Updating RECORD file of %s", basename(wheel_file))
            return
        libs = set()
        licenses = {}
        if args.CHECK_LIBS or args.CHECK_LICENSES:
            libs, licenses = parse_license_json(args.LICENSE_JSON)
        real_libs = set()
        for fn in ctx.iter_files():
            path_split = fn.split(os.sep)
            name = path_split[-1]
            if f"{args.LIB_SDIR}/" in fn and ".so" in name:
                if args.NO_LIBS:
                    logger.error(f"found possible .so: {fn}")
                    exit(1)
                if args.CHECK_LIBS:
                    # libxxx-xxxx.so(.xxx)
                    name = "".join(name.split(".so")[:-1])
                    # libxxx-xxxx
                    name = "-".join(name.split("-")[:-1])
                    real_libs.add(name)
            if args.CHECK_LICENSES and licenses.get(name, None) is not None:
                licenses[name] = True
        ok = True
        if args.CHECK_LIBS:
            if libs != real_libs:
                ok = False
                logger.error(f"libs check failed. libs: {libs}, real_libs: {real_libs}")
        if args.CHECK_LICENSES:
            for k, v in licenses.items():
                if v != True:
                    ok = False
                    logger.error(f"{k} is not found")
        if not ok:
            logger.error("check is not passed.")
            exit(1)
        logger.info("check passed.")
        logger.info("Updating RECORD file of %s", basename(wheel_file))

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
