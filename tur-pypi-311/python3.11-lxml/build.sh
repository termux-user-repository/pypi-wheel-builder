TERMUX_PKG_HOMEPAGE=https://github.com/lxml/lxml
TERMUX_PKG_DESCRIPTION="A straightforward binding of libsass for Python"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="5.3.1"
TERMUX_PKG_SRCURL=https://github.com/lxml/lxml/releases/download/lxml-$TERMUX_PKG_VERSION/lxml-$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=106b7b5d2977b339f1e97efe2778e2ab20e99994cbb0ec5e55771ed0795920c8
TERMUX_PKG_DEPENDS="python3.11"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_VERSION_REGEXP="\d+\.\d+\.\d+"
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

TERMUX_PYTHON_VERSION=3.11
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_pkg_auto_update() {
	local tag="$(termux_github_api_get_tag "${TERMUX_PKG_SRCURL}" "${TERMUX_PKG_UPDATE_TAG_TYPE}")"
	if grep -qP "^lxml-${TERMUX_PKG_UPDATE_VERSION_REGEXP}\$" <<<"$tag"; then
		termux_pkg_upgrade_version "$tag"
	else
		echo "WARNING: Skipping auto-update: Not stable release($tag)"
	fi
}

termux_step_post_get_source() {
	export PATH="$TERMUX_PREFIX/opt/python$TERMUX_PYTHON_VERSION/cross/bin:$PATH"
}

termux_step_pre_configure() {
	export STATIC_DEPS=true
	export TERMUX_CONFIGURE_CMD_EXTRA="--build=x86_64-linux-gnu --host=$TERMUX_HOST_PLATFORM"

	export CFLAGS+=" -fPIC"
}
