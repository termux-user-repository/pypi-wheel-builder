TERMUX_PKG_HOMEPAGE=https://python-pillow.org/
TERMUX_PKG_DESCRIPTION="Python Imaging Library"
TERMUX_PKG_LICENSE="custom"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="10.3.0"
TERMUX_PKG_SRCURL=https://github.com/python-pillow/Pillow/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=5a2f1a812237bf9bd57f283422f46ca97a1c3d43d5f67b9bf8a0d499c4b97c85
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="freetype, libimagequant, libjpeg-turbo, libraqm, libtiff, libwebp, libxcb, littlecms, openjpeg, python, zlib"
TERMUX_PKG_LICENSE_FILE="LICENSE"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, 'setuptools==67.8'"
TERMUX_PKG_BUILD_IN_SRC=true

TERMUX_PYTHON_VERSION=3.11
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true
# XXX: Licenses are included in the LICENSE file of Pillow.
TUR_PACKAGE_WHEEL_LICENSE=false

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_post_make_install() {
	if [ ! -e "$TERMUX_PYTHON_HOME/site-packages/pillow-$TERMUX_PKG_VERSION.dist-info" ]; then
		termux_error_exit "Package ${TERMUX_PKG_NAME} doesn't build properly."
	fi
}
