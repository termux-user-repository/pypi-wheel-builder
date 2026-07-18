TERMUX_PKG_HOMEPAGE=https://github.com/scikit-build/ninja-python-distributions
TERMUX_PKG_DESCRIPTION="A small build system with a focus on speed (Python Wheel Distribution)"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="1.11.1.1"
TERMUX_PKG_SRCURL=git+https://github.com/scikit-build/ninja-python-distributions
TERMUX_PKG_GIT_BRANCH="$TERMUX_PKG_VERSION"
TERMUX_PKG_DEPENDS="libc++, python, python-pip"
TERMUX_PKG_BUILD_DEPENDS="libandroid-spawn-static"
TERMUX_PKG_PYTHON_COMMON_BUILD_DEPS="wheel, 'setuptools-scm[toml]', scikit-build"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

TERMUX_PYTHON_VERSION=3.14
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TERMUX_PYTHON_CROSSENV_BUILDHOME=$TERMUX_PYTHON_CROSSENV_PREFIX/build/lib/python${TERMUX_PYTHON_VERSION}
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true
TUR_AUTO_BUILD_WHEEL=false

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

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
		local ninja_source_url="https://github.com/ninja-build/ninja/archive/v${new_ninja_version}.tar.gz"
		local ninja_source_sha256
		curl -LC - "$ninja_source_url" -o "${tmpdir}/${new_ninja_version}.tar.gz"
		ninja_source_sha256=$(sha256sum "${tmpdir}/${new_ninja_version}.tar.gz" | sed -e "s| .*$||")

		sed -i "${TERMUX_PKG_BUILDER_DIR}/build.sh" \
			-e "s|^_NINJA_VERSION=.*|_NINJA_VERSION=${new_ninja_version}|" \
			-e "s|^_NINJA_SHA256=.*|_NINJA_SHA256=${ninja_source_sha256}|"

		rm -fr "${tmpdir}"
	fi

	termux_pkg_upgrade_version "$latest_tag"
}

termux_step_post_get_source() {
	local _ninja_source_file="$TERMUX_PKG_CACHEDIR/ninja-source-$_NINJA_VERSION.tar.gz"

	termux_download $_NINJA_SRCURL $_ninja_source_file $_NINJA_SHA256

	tar -xf $_ninja_source_file
	mv ninja-$_NINJA_VERSION ninja-source

	export PATH="$TERMUX_PREFIX/opt/python$TERMUX_PYTHON_VERSION/cross/bin:$PATH"
}

termux_step_configure() {
	CXXFLAGS+=" $CPPFLAGS"
	LDFLAGS+=" -l:libandroid-spawn.a"

	pushd ninja-source
	./configure.py
	termux_setup_ninja
	ninja -j $TERMUX_PKG_MAKE_PROCESSES
	popd # ninja-source
}

termux_step_make_install() {
	termux_setup_cmake

	python setup.py bdist_wheel -- \
		-DUSE_PREBUILT_NINJA_BINARY:BOOL=ON \
		-DPREBUILT_NINJA_PATH="$TERMUX_PKG_SRCDIR/ninja-source/ninja"

	rm -f $TERMUX_PREFIX/bin/.placeholder
	touch $TERMUX_PREFIX/bin/.placeholder

	local native_wheel_arch
	case "$TERMUX_ARCH" in
		aarch64) native_wheel_arch=arm64_v8a ;;
		arm)     native_wheel_arch=armeabi_v7a ;;
		x86_64)  native_wheel_arch=x86_64 ;;
		i686)    native_wheel_arch=x86 ;;
		*)
			echo "ERROR: Unknown architecture: $TERMUX_ARCH"
			return 1 ;;
	esac

	# Convert it to a generic wheel
	mv ./dist/ninja-$TERMUX_PKG_VERSION-cp314-cp314-android_$TERMUX_ARCH.whl \
		./dist/ninja-$TERMUX_PKG_VERSION-py2.py3-none-android_${TERMUX_PKG_API_LEVEL}_$native_wheel_arch.whl

	# Also provide for linux (python<=3.12)
	cp ./dist/ninja-$TERMUX_PKG_VERSION-py2.py3-none-android_${TERMUX_PKG_API_LEVEL}_$native_wheel_arch.whl \
		./dist/ninja-$TERMUX_PKG_VERSION-py2.py3-none-linux_$TERMUX_ARCH.whl
}

tur_install_wheel_license() {
	# Install license of ninja binary
	cp $TERMUX_PKG_SRCDIR/ninja-source/COPYING COPYING-ninja-binary
	# Install license of libandroid-spawn
	cp $TERMUX_PREFIX/share/doc/libandroid-spawn/LICENSE LICENSE-libandroid-spawn
}
