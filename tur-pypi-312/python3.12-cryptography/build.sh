TERMUX_PKG_HOMEPAGE=https://github.com/pyca/cryptography
TERMUX_PKG_DESCRIPTION="Provides cryptographic recipes and primitives to Python developers"
TERMUX_PKG_LICENSE="Apache-2.0, BSD 3-Clause"
TERMUX_PKG_LICENSE_FILE="LICENSE, LICENSE.APACHE, LICENSE.BSD"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="45.0.2"
TERMUX_PKG_SRCURL=https://github.com/pyca/cryptography/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=061700c5de59729f21064db16edbf4e31bd5c8a024e71cbd5f22ebdb02d95cbb
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="openssl, python, python-pip"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, cffi, setuptools-rust"
TERMUX_PKG_PYTHON_BUILD_DEPS="maturin"

TERMUX_PYTHON_VERSION=3.12
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true
TUR_AUTO_BUILD_WHEEL=false
TUR_WHEEL_DIR="wheels/"

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_configure() {
	termux_setup_rust
	export CARGO_BUILD_TARGET=${CARGO_TARGET_NAME}
	export PYO3_CROSS_PYTHON_VERSION=$TERMUX_PYTHON_VERSION
	export PYO3_CROSS_LIB_DIR=$TERMUX_PREFIX/lib
	export PYTHONPATH=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages
}

termux_step_post_make_install() {
	pip wheel .

	mkdir -p wheels
	local _pyver="${TERMUX_PYTHON_VERSION/./}"
	# Fix wheel name for arm
	if [ "$TERMUX_ARCH" = "arm" ]; then
		mv cryptography-$TERMUX_PKG_VERSION-cp312-abi3-linux_armv7l.whl \
			./wheels/cryptography-$TERMUX_PKG_VERSION-cp$_pyver-cp$_pyver-linux_armv7l.whl
	else
	mv cryptography-$TERMUX_PKG_VERSION-cp312-abi3-linux_$TERMUX_ARCH.whl \
		./wheels/cryptography-$TERMUX_PKG_VERSION-cp$_pyver-cp$_pyver-linux_$TERMUX_ARCH.whl
	fi
}
