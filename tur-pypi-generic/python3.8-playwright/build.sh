TERMUX_PKG_HOMEPAGE=https://github.com/Microsoft/playwright-python
TERMUX_PKG_DESCRIPTION="Python version of the Playwright testing and automation library"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION=1.34.0
TERMUX_PKG_SRCURL=git+https://github.com/microsoft/playwright-python
TERMUX_PKG_DEPENDS="python3.8"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel"
TERMUX_PKG_BLACKLISTED_ARCHES="arm, i686"

TERMUX_PYTHON_VERSION=3.8
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH

TUR_AUDIT_WHEEL_NO_LIBS=true

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_post_get_source() {
	# The only binary file is the prebuilt node. Use a script instead.
	sed "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" \
		$TERMUX_PKG_BUILDER_DIR/node-wrapper.sh.in > node-wrapper.sh
	chmod +x node-wrapper.sh

	export PATH="$TERMUX_PREFIX/opt/python$TERMUX_PYTHON_VERSION/cross/bin:$PATH"
}
