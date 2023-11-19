TERMUX_PKG_HOMEPAGE=https://grpc.io/
TERMUX_PKG_DESCRIPTION="High performance, open source, general RPC framework that puts mobile and HTTP/2 first"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_SRCURL=git+https://github.com/grpc/grpc
TERMUX_PKG_VERSION="1.59.3"
TERMUX_PKG_DEPENDS="abseil-cpp, c-ares, ca-certificates, libc++, libre2, openssl, python3.7, zlib"
TERMUX_PKG_BUILD_DEPENDS="gflags, gflags-static"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, 'setuptools==65.4.1', 'Cython<3'"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

TERMUX_PYTHON_VERSION=3.7
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true

source $TERMUX_SCRIPTDIR/common-files/tur_elf_cleaner_for_wheel.sh

termux_step_post_get_source() {
	export PATH="$TERMUX_PREFIX/opt/python$TERMUX_PYTHON_VERSION/cross/bin:$PATH"
}

termux_step_pre_configure() {
	rm CMakeLists.txt Makefile Rakefile

	export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
	export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
	export GRPC_PYTHON_BUILD_SYSTEM_CARES=1
	export GRPC_PYTHON_BUILD_SYSTEM_RE2=1
	export GRPC_PYTHON_BUILD_SYSTEM_ABSL=1
	export GRPC_PYTHON_BUILD_WITH_CYTHON=1

	LDFLAGS="${LDFLAGS/-lpython3.7/-lpython3.7m}"
}
