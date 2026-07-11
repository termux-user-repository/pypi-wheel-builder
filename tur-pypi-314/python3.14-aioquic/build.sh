TERMUX_PKG_HOMEPAGE=https://github.com/aiortc/aioquic
TERMUX_PKG_DESCRIPTION="QUIC and HTTP/3 implementation in Python"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="1.3.0"
TERMUX_PKG_SRCURL=https://github.com/aiortc/aioquic/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=85eaf031aa48a5d5755799d2f463e6f68c965636670459840939591465ca1281
TERMUX_PKG_DEPENDS="python, python-pip"
TERMUX_PKG_PYTHON_COMMON_BUILD_DEPS="wheel"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"

TERMUX_PYTHON_VERSION=3.14
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TERMUX_PYTHON_CROSSENV_BUILDHOME=$TERMUX_PYTHON_CROSSENV_PREFIX/build/lib/python${TERMUX_PYTHON_VERSION}
TUR_AUTO_BUILD_WHEEL=false
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_make_install() {
	python setup.py bdist_wheel

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
	local pack_name="aioquic"
	local pyversion="${TERMUX_PYTHON_VERSION/./}"
	local native_wheel_ext="${TERMUX_PKG_VERSION}-cp310-abi3-android_${TERMUX_ARCH}.whl"
	local cross_wheel_ext="${TERMUX_PKG_VERSION}-cp${pyversion}-none-any.whl"
	local release_whl_ext="${TERMUX_PKG_VERSION}-cp${pyversion}-cp${pyversion}-android_${TERMUX_PKG_API_LEVEL}_${native_wheel_arch}.whl"

	local _whl_orig="dist/${pack_name}-${native_wheel_ext}"
	local _whl_dest="dist/${pack_name}-${cross_wheel_ext}"
	local _whl_release="dist/${pack_name}-${release_whl_ext}"
	mv "$_whl_orig" "$_whl_dest"
	pip install --force-reinstall --no-deps --prefix "$TERMUX_PREFIX" "$_whl_dest"
	mv "$_whl_dest" "$_whl_release"
}
