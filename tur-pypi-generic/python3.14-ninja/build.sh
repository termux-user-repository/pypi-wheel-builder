TERMUX_PKG_HOMEPAGE=https://github.com/scikit-build/ninja-python-distributions
TERMUX_PKG_DESCRIPTION="A small build system with a focus on speed (Python Wheel Distribution)"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="1.13.0"
TERMUX_PKG_SRCURL=git+https://github.com/scikit-build/ninja-python-distributions
TERMUX_PKG_GIT_BRANCH="$TERMUX_PKG_VERSION"
TERMUX_PKG_DEPENDS="libc++, python, python-pip"
TERMUX_PKG_BUILD_DEPENDS="libandroid-spawn-static"
TERMUX_PKG_PYTHON_COMMON_BUILD_DEPS="wheel, 'setuptools-scm[toml]', scikit-build"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

TERMUX_PYTHON_VERSION=3.14
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TERMUX_PYTHON_CROSSENV_BUILDHOME=$TERMUX_PYTHON_CROSSENV_PREFIX/build/lib/python${TERMUX_PYTHON_VERSION}
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true
TUR_AUTO_BUILD_WHEEL=false

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_configure() {
	CXXFLAGS+=" $CPPFLAGS"
	LDFLAGS+=" -l:libandroid-spawn.a"

	pushd ninja-upstream
	./configure.py
	termux_setup_ninja
	ninja -j $TERMUX_PKG_MAKE_PROCESSES
	popd # ninja-upstream
}

termux_step_make_install() {
	termux_setup_cmake

	export SETUPTOOLS_SCM_PRETEND_VERSION="1.13.0"
	export CMAKE_ARGS="
-DUSE_PREBUILT_NINJA_BINARY:BOOL=ON
-DPREBUILT_NINJA_PATH=$TERMUX_PKG_SRCDIR/ninja-upstream/ninja
"

	pip wheel .

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
	mkdir -p dist
	cp ninja-$TERMUX_PKG_VERSION-py3-none-android_$TERMUX_ARCH.whl \
		./dist/ninja-$TERMUX_PKG_VERSION-py3-none-android_${TERMUX_PKG_API_LEVEL}_$native_wheel_arch.whl

	# Also provide for linux (python<=3.12)
	cp ninja-$TERMUX_PKG_VERSION-py3-none-android_$TERMUX_ARCH.whl \
		./dist/ninja-$TERMUX_PKG_VERSION-py3-none-linux_$TERMUX_ARCH.whl
}

tur_install_wheel_license() {
	# Install license of ninja binary
	cp $TERMUX_PKG_SRCDIR/ninja-upstream/COPYING COPYING-ninja-binary
	# Install license of libandroid-spawn
	cp $TERMUX_PREFIX/share/doc/libandroid-spawn/LICENSE LICENSE-libandroid-spawn
}
