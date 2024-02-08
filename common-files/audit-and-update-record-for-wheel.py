#!/usr/bin/env python3
# audit-and-update-record-for-wheel.py - Update RECORD file of a wheel.
#
from __future__ import annotations

import argparse
import logging
from os.path import abspath, basename, exists, isfile
import os

from auditwheel.wheeltools import InWheel

logger = logging.getLogger(__name__)

def configure_parser(p):
    p.add_argument(
        "-w",
        "--wheel-dir",
        dest="WHEEL_DIR",
        type=abspath,
        help=("Directory to store delocated wheels (default:" ' "wheelhouse/")'),
        default="wheelhouse/",
    )
    p.add_argument("WHEEL_FILE", help="Path to wheel file.", nargs="+")
    p.set_defaults(func=execute)


def execute(args, p):
    for wheel_file in args.WHEEL_FILE:
        if not isfile(wheel_file):
            p.error("cannot access %s. No such file" % wheel_file)

        if not exists(args.WHEEL_DIR):
            os.makedirs(args.WHEEL_DIR)

        out_wheel=os.path.join("wheelhouse", basename(wheel_file))
        with InWheel(in_wheel=wheel_file, out_wheel=out_wheel):
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
