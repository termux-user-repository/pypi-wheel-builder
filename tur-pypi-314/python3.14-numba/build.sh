TERMUX_PKG_HOMEPAGE=https://numba.pydata.org/
TERMUX_PKG_DESCRIPTION="A lightweight LLVM python binding for writing JIT compilers"
# LICENSES: custom
TERMUX_PKG_LICENSE="BSD 2-Clause, Apache-2.0"
TERMUX_PKG_LICENSE_FILE="LICENSE, LICENSES.third-party"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.66.0"
TERMUX_PKG_SRCURL="https://github.com/numba/numba/archive/refs/tags/${TERMUX_PKG_VERSION[0]}.tar.gz"
TERMUX_PKG_SHA256=1a13c627082d32253efeba6e619ce3c8c6b53a18a27f826938885fa670e5ae89
TERMUX_PKG_DEPENDS="libc++, python, python-numpy, python-pip"
TERMUX_PKG_PYTHON_COMMON_BUILD_DEPS="wheel"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true

TERMUX_PYTHON_VERSION=3.14
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TERMUX_PYTHON_CROSSENV_BUILDHOME=$TERMUX_PYTHON_CROSSENV_PREFIX/build/lib/python${TERMUX_PYTHON_VERSION}
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true
TUR_AUTO_BUILD_WHEEL=false
TUR_PACKAGE_WHEEL_LICENSE=false

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_configure() {
	:
}

termux_step_make_install() {
	LDFLAGS+=" -Wl,--no-as-needed -lpython${TERMUX_PYTHON_VERSION}"
	LDFLAGS+=" -fopenmp -static-openmp"

	export NUMPY_INCLUDE_DIR="$TERMUX_PYTHON_HOME/site-packages/numpy/_core/include"
	pip install . --prefix="$TERMUX_PREFIX" -vv --no-build-isolation --no-deps
	pip wheel . --no-build-isolation --no-deps

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

	mkdir -p dist
	local _pyver="${TERMUX_PYTHON_VERSION/./}"
	cp numba-$TERMUX_PKG_VERSION-cp$_pyver-cp$_pyver-android_$TERMUX_ARCH.whl \
		./dist/numba-$TERMUX_PKG_VERSION-cp$_pyver-cp$_pyver-android_${TERMUX_PKG_API_LEVEL}_$native_wheel_arch.whl
}

termux_step_post_massage() {
	tur_build_wheel
}
