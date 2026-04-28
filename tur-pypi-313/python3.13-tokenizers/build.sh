TERMUX_PKG_HOMEPAGE=https://github.com/huggingface/tokenizers
TERMUX_PKG_DESCRIPTION="Fast State-of-the-Art Tokenizers optimized for Research and Production"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="0.23.1"
TERMUX_PKG_SRCURL=https://github.com/huggingface/tokenizers/archive/refs/tags/v$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=aa906ad27ece40261e075e171e4a8873c2c5cfdbb64205170735d425f214c7ef
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libc++, python, python-pip"
TERMUX_PKG_PYTHON_COMMON_BUILD_DEPS="wheel"
TERMUX_PKG_PYTHON_CROSS_BUILD_DEPS="'maturin<1.13'"
TERMUX_PKG_BUILD_IN_SRC=true

TERMUX_PYTHON_VERSION=3.13
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TERMUX_PYTHON_CROSSENV_BUILDHOME=$TERMUX_PYTHON_CROSSENV_PREFIX/build/lib/python${TERMUX_PYTHON_VERSION}
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true
TUR_AUTO_BUILD_WHEEL=false
TUR_WHEEL_DIR="target/wheels"

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_post_get_source() {
	rm -f $TERMUX_PKG_SRCDIR/Makefile
}

termux_step_pre_configure() {
	TERMUX_PKG_SRCDIR+="/bindings/python"
	TERMUX_PKG_BUILDDIR+="/bindings/python"

	termux_setup_rust

	# Tokenizers uses some extra libs that requires `core` crates, but
	# the toolchain provided by rustup doesn't have them (Android is at
	# tier 2). Use nightly toolchain and enable `build-std` feature to
	# build these crates.
	rustup toolchain install nightly
	rustup component add rust-src --toolchain nightly
	echo "nightly" > $TERMUX_PKG_SRCDIR/rust-toolchain
}

termux_step_make() {
	:
}

termux_step_make_install() {
	export CARGO_BUILD_TARGET=${CARGO_TARGET_NAME}
	export PYO3_CROSS_PYTHON_VERSION=$TERMUX_PYTHON_VERSION
	export PYO3_CROSS_LIB_DIR=$TERMUX_PREFIX/lib
	export PYTHONPATH=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages
	export ANDROID_API_LEVEL="$TERMUX_PKG_API_LEVEL"

	build-python -m maturin build \
				--target $CARGO_BUILD_TARGET \
				--release --skip-auditwheel \
				--interpreter python${TERMUX_PYTHON_VERSION} \
				-Z build-std

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
	local pack_name="tokenizers"
	local pyversion="${TERMUX_PYTHON_VERSION/./}"
	local native_wheel_ext="${TERMUX_PKG_VERSION}-cp310-abi3-android_${ANDROID_API_LEVEL}_${native_wheel_arch}.whl"
	local cross_wheel_ext="${TERMUX_PKG_VERSION}-cp${pyversion}-none-any.whl"
	local release_whl_ext="${TERMUX_PKG_VERSION}-cp${pyversion}-cp${pyversion}-android_${ANDROID_API_LEVEL}_${native_wheel_arch}.whl"

	local _whl_orig="target/wheels/${pack_name}-${native_wheel_ext}"
	local _whl_dest="target/wheels/${pack_name}-${cross_wheel_ext}"
	local _whl_release="target/wheels/${pack_name}-${release_whl_ext}"
	mv "$_whl_orig" "$_whl_dest"
	pip install --force-reinstall --no-deps --prefix "$TERMUX_PREFIX" "$_whl_dest"
	mv "$_whl_dest" "$_whl_release"
}
