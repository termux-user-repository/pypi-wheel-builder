TERMUX_PKG_HOMEPAGE=https://github.com/scikit-build/cmake-python-distributions
TERMUX_PKG_DESCRIPTION="A small build system with a focus on speed (Python Wheel Distribution)"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="3.28.4"
TERMUX_PKG_SRCURL=https://github.com/scikit-build/cmake-python-distributions/archive/refs/tags/$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=33f277c8ba3cd12b6a7e6c2d05c2a4ee113fc1c752c71e60d3782a1352a22602
TERMUX_PKG_DEPENDS="libarchive, libc++, libcurl, libexpat, jsoncpp, libuv, python3.11, rhash, zlib"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, 'setuptools==65.4.1', 'setuptools-scm[toml]', scikit-build"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_INSTALL_PREFIX=$TERMUX_PREFIX/opt/cmake-wheel-dist
"

TERMUX_PYTHON_VERSION=3.11
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUTO_BUILD_WHEEL=false
TUR_LIB_LICENSE_JSON="$TERMUX_PKG_BUILDER_DIR/licenses.json"

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

_CMAKE_VERSION=3.28.4
_CMAKE_SRCURL="https://www.cmake.org/files/v${_CMAKE_VERSION:0:4}/cmake-${_CMAKE_VERSION}.tar.gz"
_CMAKE_SHA256=eb9c787e078848dc493f4f83f8a4bbec857cd1f38ab6425ce8d2776a9f6aa6fb

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

	local new_cmake_version="$(echo $latest_tag | cut -d'.' -f1-3)"

	if [[ "$new_cmake_version" != "$_CMAKE_VERSION" ]]; then
		local tmpdir=$(mktemp -d)
		local cmake_source_url="https://www.cmake.org/files/v${new_cmake_version:0:4}/cmake-${new_cmake_version}.tar.gz"
		local cmake_source_sha256
		curl -LC - "$cmake_source_url" -o "${tmpdir}/${new_cmake_version}.tar.gz"
		cmake_source_sha256=$(sha256sum "${tmpdir}/${new_cmake_version}.tar.gz" | sed -e "s| .*$||")

		sed -i "${TERMUX_PKG_BUILDER_DIR}/build.sh" \
			-e "s|^_CMAKE_VERSION=.*|_CMAKE_VERSION=${new_cmake_version}|" \
			-e "s|^_CMAKE_SHA256=.*|_CMAKE_SHA256=${cmake_source_sha256}|"

		rm -fr "${tmpdir}"
	fi

	termux_pkg_upgrade_version "$latest_tag"
}

termux_step_post_get_source() {
	local _cmake_source_file="$TERMUX_PKG_CACHEDIR/cmake-source.tar.gz"

	termux_download $_CMAKE_SRCURL $_cmake_source_file $_CMAKE_SHA256

	tar -xf $_cmake_source_file
	mv cmake-$_CMAKE_VERSION cmake-source

	export PATH="$TERMUX_PREFIX/opt/python$TERMUX_PYTHON_VERSION/cross/bin:$PATH"
}

termux_step_configure() {
	pushd cmake-source
	termux_setup_cmake
	termux_setup_ninja
	local _origin_srcdir="$TERMUX_PKG_SRCDIR"
	TERMUX_PKG_SRCDIR+="/cmake-source"
	mkdir -p cmake-build && cd cmake-build
	termux_step_configure_cmake
	ninja -j $TERMUX_PKG_MAKE_PROCESSES
	ninja -j 1 install
	popd # cmake-source

	TERMUX_PKG_SRCDIR="$_origin_srcdir"
}

termux_step_make_install() {
	termux_setup_cmake

	python setup.py bdist_wheel -- \
		-DBUILD_CMAKE_FROM_SOURCE:BOOL=OFF \
		-DRUN_CMAKE_TEST:BOOL=OFF \
		-DCMakeProject_BINARY_DISTRIBUTION_DIR="$TERMUX_PREFIX/opt/cmake-wheel-dist"

	# Convert it to a generic wheel
	mv ./dist/cmake-$TERMUX_PKG_VERSION-cp311-cp311-linux_$TERMUX_ARCH.whl \
		./dist/cmake-$TERMUX_PKG_VERSION-py3-none-linux_$TERMUX_ARCH.whl
}

tur_install_wheel_license() {
	cp $TERMUX_PREFIX/share/doc/libarchive/copyright libarchive-LICENSE
	cp $TERMUX_PREFIX/share/doc/jsoncpp/copyright jsoncpp-LICENSE
	cp $TERMUX_PREFIX/share/doc/rhash/copyright rhash-LICENSE
	cp $TERMUX_PREFIX/share/doc/libuv/LICENSE libuv-LICENSE
	cp $TERMUX_PREFIX/share/doc/libxml2/copyright libxml2-LICENSE
}
