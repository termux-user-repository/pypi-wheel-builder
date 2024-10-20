TERMUX_PKG_HOMEPAGE=https://github.com/decathorpe/mitmproxy_wireguard
TERMUX_PKG_DESCRIPTION="WireGuard frontend for mitmproxy"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="0.1.23"
TERMUX_PKG_SRCURL=https://github.com/decathorpe/mitmproxy_wireguard/archive/refs/tags/$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=29eac8ffcb235194b9f1aba9e0fe3e024aa8417427005eabeb30c1870c808b35
TERMUX_PKG_DEPENDS="libc++, openssl, python3.7"
TERMUX_PKG_BUILD_DEPENDS="python3.7-cross"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"

TERMUX_PYTHON_VERSION=3.7
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python37-crossenv-prefix-$TERMUX_ARCH

TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true
TUR_AUTO_BUILD_WHEEL=false
TUR_WHEEL_DIR="target/wheels"

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_post_get_source() {
	export PATH="$TERMUX_PREFIX/opt/python$TERMUX_PYTHON_VERSION/cross/bin:$PATH"
}

termux_step_pre_configure() {
	termux_setup_rust

	termux_setup_python_pip

	build-pip install maturin
}

termux_step_make_install() {
	export CARGO_BUILD_TARGET=${CARGO_TARGET_NAME}
	export PYO3_CROSS_LIB_DIR=$TERMUX_PREFIX/lib
	export PYTHONPATH=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages

	build-python -m maturin build --release --skip-auditwheel --target $CARGO_BUILD_TARGET

	# Fix wheel name for arm
	if [ "$TERMUX_ARCH" = "arm" ]; then
		mv ./target/wheels/mitmproxy_wireguard-$TERMUX_PKG_VERSION-cp37-abi3-linux_armv7l.whl \
			./target/wheels/mitmproxy_wireguard-$TERMUX_PKG_VERSION-py37-none-any.whl
	fi

	pip install --no-deps ./target/wheels/*.whl --prefix $TERMUX_PREFIX

	# Fix wheel name, although it it built with tag `cp37-abi3`, but it is linked against `python3.7m.so`
	# so it will not work on other pythons.
	if [ "$TERMUX_ARCH" = "arm" ]; then
		mv ./target/wheels/mitmproxy_wireguard-$TERMUX_PKG_VERSION-py37-none-any.whl \
			./target/wheels/mitmproxy_wireguard-$TERMUX_PKG_VERSION-cp37-cp37m-linux_armv7l.whl
	else
		mv ./target/wheels/mitmproxy_wireguard-$TERMUX_PKG_VERSION-cp37-abi3-linux_$TERMUX_ARCH.whl \
			./target/wheels/mitmproxy_wireguard-$TERMUX_PKG_VERSION-cp37-cp37m-linux_$TERMUX_ARCH.whl
	fi
}
