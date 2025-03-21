TERMUX_PKG_HOMEPAGE=https://www.pycryptodome.org/
TERMUX_PKG_DESCRIPTION="A self-contained Python package of low-level cryptographic primitives"
TERMUX_PKG_LICENSE="BSD 2-Clause, Public Domain"
TERMUX_PKG_LICENSE_FILE="LICENSE.rst"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="3.22.0"
TERMUX_PKG_SRCURL="https://github.com/Legrandin/pycryptodome/archive/refs/tags/v${TERMUX_PKG_VERSION}x.tar.gz"
TERMUX_PKG_SHA256=8c49ffdb694dd35f526c9eadda243d8307065582578bc4bd34aca13218e9500d
TERMUX_PKG_DEPENDS="python3.11"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, 'setuptools==67.8.0'"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true

TERMUX_PYTHON_VERSION=3.11
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_post_get_source() {
	export PATH="$TERMUX_PREFIX/opt/python$TERMUX_PYTHON_VERSION/cross/bin:$PATH"
}

termux_step_pre_configure() {
	LDFLAGS+=" -Wl,--no-as-needed -lpython${TERMUX_PYTHON_VERSION}"
}

termux_step_make() {
	:
}

termux_step_make_install() {
	pip install . --prefix=$TERMUX_PREFIX -vv --no-build-isolation --no-deps

	python setup.py bdist_wheel
}

termux_step_post_make_install() {
	mv ./dist/pycryptodomex-$TERMUX_PKG_VERSION-cp37-abi3-linux_$TERMUX_ARCH.whl \
		./dist/pycryptodomex-$TERMUX_PKG_VERSION-cp311-cp311-linux_$TERMUX_ARCH.whl
}
