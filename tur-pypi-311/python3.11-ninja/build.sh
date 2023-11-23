TERMUX_PKG_HOMEPAGE=https://github.com/scikit-build/ninja-python-distributions
TERMUX_PKG_DESCRIPTION="A small build system with a focus on speed (Python Wheel Distribution)"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="1.11.1"
TERMUX_PKG_SRCURL=https://github.com/scikit-build/ninja-python-distributions/archive/refs/tags/$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=8ed58848cfecf0f70279e960d74fe79b4adacd5f22b7389e2a25c8853dc02f57
TERMUX_PKG_DEPENDS="libc++, python"
TERMUX_PKG_BUILD_DEPENDS="libandroid-spawn-static"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, 'setuptools==65.4.1', scikit-build"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

TERMUX_PYTHON_VERSION=3.11
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUTO_BUILD_WHEEL=false

source $TERMUX_SCRIPTDIR/common-files/tur_elf_cleaner_for_wheel.sh

_NINJA_VERSION="1.11.1"
_NINJA_SRCURL="https://github.com/ninja-build/ninja/archive/v${_NINJA_VERSION}.tar.gz"
_NINJA_SHA256="31747ae633213f1eda3842686f83c2aa1412e0f5691d1c14dbbcc67fe7400cea"

termux_pkg_auto_update() {
	local latest_tag
	latest_tag=$(termux_github_api_get_tag "${TERMUX_PKG_SRCURL}" "${TERMUX_PKG_UPDATE_TAG_TYPE}")

	if [[ -z "${latest_tag}" ]]; then
		termux_error_exit "ERROR: Unable to get tag from ${TERMUX_PKG_SRCURL}"
	fi

	if [[ "${latest_tag}" == "${TERMUX_PKG_VERSION}" ]]; then
		echo "INFO: No update needed. Already at version '${TERMUX_PKG_VERSION}'."
		return
	fi

	local new_ninja_version="$(echo $latest_tag | cut -d'.' -f1-3)"

	if [[ "$new_ninja_version" != "$_NINJA_VERSION" ]]; then
		local tmpdir=$(mktemp -d)
		local ninja_source_sha256
		curl -LC - "$_NINJA_SRCURL" -o "${tmpdir}/${new_ninja_version}.tar.gz"
		ninja_source_sha256=$(sha256sum "${tmpdir}/${new_ninja_version}.tar.gz" | sed -e "s| .*$||")

		sed -i "${TERMUX_PKG_BUILDER_DIR}/build.sh" \
			-e "s|^_NINJA_VERSION=.*|_NINJA_VERSION=${new_ninja_version}|" \
			-e "s|^_NINJA_SHA256=.*|_NINJA_SHA256=${ninja_source_sha256}|"

		rm -fr "${tmpdir}"
	fi

	termux_pkg_upgrade_version "$latest_tag"
}

termux_step_post_get_source() {
	local _ninja_source_file="$TERMUX_PKG_CACHEDIR/ninja-source.tar.gz"

	termux_download $_NINJA_SRCURL $_ninja_source_file $_NINJA_SHA256

	tar -xf $_ninja_source_file
	mv ninja-$_NINJA_VERSION ninja-source
}

termux_step_configure() {
	CXXFLAGS+=" $CPPFLAGS"
	LDFLAGS+=" -l:libandroid-spawn.a"

	pushd ninja-source
	./configure.py
	termux_setup_ninja
	ninja -j $TERMUX_MAKE_PROCESSES
	popd # ninja-source
}

termux_step_make_install() {
	termux_setup_cmake

	python setup.py bdist_wheel -- \
		-DUSE_PREBUILT_NINJA_BINARY:BOOL=ON \
		-DPREBUILT_NINJA_PATH="$TERMUX_PKG_SRCDIR/ninja-source/ninja"

	rm -f $TERMUX_PREFIX/bin/.placeholder
	touch $TERMUX_PREFIX/bin/.placeholder
}
