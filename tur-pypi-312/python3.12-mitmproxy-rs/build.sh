TERMUX_PKG_HOMEPAGE=https://github.com/mitmproxy/mitmproxy_rs
TERMUX_PKG_DESCRIPTION="The Rust bits in mitmproxy"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="0.11.2"
TERMUX_PKG_SRCURL=https://github.com/mitmproxy/mitmproxy_rs/archive/refs/tags/v$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=4d74364e2a1a4ae956cb687b3308618e4dff3dd29d73491fa311bb26a519439e
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libc++, openssl, python"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel"
TERMUX_PKG_PYTHON_BUILD_DEPS="maturin"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"

TERMUX_PYTHON_VERSION=3.12
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true
TUR_AUTO_BUILD_WHEEL=false
TUR_WHEEL_DIR="target/wheels"

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_pre_configure() {
	termux_setup_rust

	LDFLAGS+=" -Wl,--no-as-needed,-lpython${TERMUX_PYTHON_VERSION}"
}

termux_step_make() {
	:
}

termux_step_make_install() {
	export CARGO_BUILD_TARGET=${CARGO_TARGET_NAME}
	export PYO3_CROSS_LIB_DIR=$TERMUX_PREFIX/lib
	export PYTHONPATH=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages

	cd mitmproxy-rs
	build-python -m maturin build \
				--target $CARGO_BUILD_TARGET \
				--release --skip-auditwheel \
				--interpreter python${TERMUX_PYTHON_VERSION}

	local _pyver="${TERMUX_PYTHON_VERSION/./}"
	# Fix wheel name, although it it built with tag `cp310-abi3`, but it is linked against `python3.x.so`
	# so it will not work on other pythons.
	if [ "$TERMUX_ARCH" = "arm" ]; then
		mv ../target/wheels/mitmproxy_rs-$TERMUX_PKG_VERSION-cp310-abi3-linux_armv7l.whl \
			../target/wheels/mitmproxy_rs-$TERMUX_PKG_VERSION-py$_pyver-none-any.whl
	else
		mv ../target/wheels/mitmproxy_rs-$TERMUX_PKG_VERSION-cp310-abi3-linux_$TERMUX_ARCH.whl \
			../target/wheels/mitmproxy_rs-$TERMUX_PKG_VERSION-cp$_pyver-cp$_pyver-linux_$TERMUX_ARCH.whl
	fi

	pip install --no-deps ../target/wheels/*.whl --prefix $TERMUX_PREFIX

	# Fix wheel name for arm
	if [ "$TERMUX_ARCH" = "arm" ]; then
		mv ../target/wheels/mitmproxy_rs-$TERMUX_PKG_VERSION-py$_pyver-none-any.whl \
			../target/wheels/mitmproxy_rs-$TERMUX_PKG_VERSION-cp$_pyver-cp$_pyver-linux_armv7l.whl
	fi
}
