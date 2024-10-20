TERMUX_PKG_HOMEPAGE=https://github.com/pyca/cryptography
TERMUX_PKG_DESCRIPTION="Provides cryptographic recipes and primitives to Python developers"
# Licenses: Apache-2.0, BSD 3-Clause, PSFL
TERMUX_PKG_LICENSE="custom"
TERMUX_PKG_LICENSE_FILE="LICENSE, LICENSE.APACHE, LICENSE.BSD, LICENSE.PSF"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION=39.0.1
TERMUX_PKG_SRCURL=https://github.com/pyca/cryptography/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=e9a4fe4d32e3161dccf9172086e1c2c96e49854fde5f9a220d40c84b9faa9b87
TERMUX_PKG_DEPENDS="libffi, openssl, python3.8"
TERMUX_PKG_BUILD_DEPENDS="python3.8-cross"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, cffi, setuptools-rust"
TERMUX_PKG_PYTHON_TARGET_DEPS="'cffi>=1.12'"

TERMUX_PYTHON_VERSION=3.8
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_post_get_source() {
	echo "Applying openssl-libs.diff"
	sed "s%@PYTHON_VERSION@%$TERMUX_PYTHON_VERSION%g" \
		$TERMUX_PKG_BUILDER_DIR/openssl-libs.diff | patch --silent -p1

	export PATH="$TERMUX_PREFIX/opt/python$TERMUX_PYTHON_VERSION/cross/bin:$PATH"
}

termux_step_configure() {
	termux_setup_rust
	export CARGO_BUILD_TARGET=${CARGO_TARGET_NAME}
	export PYO3_CROSS_LIB_DIR=$TERMUX_PREFIX/lib
}

termux_step_create_debscripts() {
	cat <<- EOF > ./postinst
	#!$TERMUX_PREFIX/bin/sh
	echo "Installing dependencies through pip..."
	pip3 install $TERMUX_PKG_PYTHON_TARGET_DEPS
	EOF
}
