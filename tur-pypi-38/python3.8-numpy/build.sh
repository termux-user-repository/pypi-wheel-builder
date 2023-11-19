TERMUX_PKG_HOMEPAGE=https://numpy.org/
TERMUX_PKG_DESCRIPTION="The fundamental package for scientific computing with Python"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="1.24.4"
TERMUX_PKG_SRCURL=git+https://github.com/numpy/numpy
TERMUX_PKG_DEPENDS="libc++, libopenblas, python3.8"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, pybind11, 'Cython<3', pythran"
# Numpy 1.25 dropped support for Python3.8
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_RM_AFTER_INSTALL="
bin/
"

TERMUX_PYTHON_VERSION=3.8
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python38-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true

source $TERMUX_SCRIPTDIR/common-files/tur_elf_cleaner_for_wheel.sh

termux_step_post_get_source() {
	export PATH="$TERMUX_PREFIX/opt/python$TERMUX_PYTHON_VERSION/cross/bin:$PATH"
}

termux_step_pre_configure() {
	export MATHLIB="m"

	LDFLAGS+=" -lm"
}
