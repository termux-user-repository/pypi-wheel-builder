TERMUX_PKG_HOMEPAGE=https://grpc.io/
TERMUX_PKG_DESCRIPTION="High performance, open source, general RPC framework that puts mobile and HTTP/2 first"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_SRCURL=git+https://github.com/grpc/grpc
TERMUX_PKG_VERSION="1.67.0"
TERMUX_PKG_DEPENDS="ca-certificates, libc++, openssl, python3.10, zlib"
TERMUX_PKG_BUILD_DEPENDS="python3.10-cross"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, setuptools, 'Cython>=3.0.0'"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

TERMUX_PYTHON_VERSION=3.10
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_post_get_source() {
	export PATH="$TERMUX_PREFIX/opt/python$TERMUX_PYTHON_VERSION/cross/bin:$PATH"
}

termux_step_pre_configure() {
	rm CMakeLists.txt Makefile Rakefile

	export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
	export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
	export GRPC_PYTHON_BUILD_WITH_CYTHON=1

	mkdir -p $TERMUX_PKG_TMPDIR/_fake_bin
	sed -e "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g" \
		-e "s|@COMPILER@|$(command -v ${CC})|g" \
		"$TERMUX_PKG_BUILDER_DIR"/wrapper.py.in \
		> $TERMUX_PKG_TMPDIR/_fake_bin/"$(basename ${CC})"
	chmod +x $TERMUX_PKG_TMPDIR/_fake_bin/"$(basename ${CC})"
	export PATH="$TERMUX_PKG_TMPDIR/_fake_bin:$PATH"
}

termux_step_post_massage() {
	# Ensure no liblog.so is linked
	local _cygrpc_so="$TERMUX_PREFIX/lib/python$TERMUX_PYTHON_VERSION/site-packages/grpc/_cython/cygrpc.cpython-${TERMUX_PYTHON_VERSION/./}.so"
	if [ ! -e "$_cygrpc_so" ]; then
		termux_error_exit "Package ${TERMUX_PKG_NAME} doesn't build properly."
	fi
	if readelf -d "$_cygrpc_so" | grep -q '(NEEDED).*\[liblog\.so'; then
		termux_error_exit "Found liblog.so linked."
	fi

	tur_build_wheel
}
