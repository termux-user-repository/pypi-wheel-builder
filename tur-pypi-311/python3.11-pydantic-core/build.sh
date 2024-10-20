TERMUX_PKG_HOMEPAGE=https://github.com/pydantic/pydantic-core
TERMUX_PKG_DESCRIPTION="Core validation logic for pydantic written in rust"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="2.24.0"
TERMUX_PKG_SRCURL=https://github.com/pydantic/pydantic-core/archive/refs/tags/v$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=b6bea059508b5b2d692b556774fb936fca380d1a8e5afde9a1cefb31d0de8aec
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libc++, python3.10"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, 'typing-extensions==4.6.0'"
TERMUX_PKG_PYTHON_BUILD_DEPS="maturin"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

TERMUX_PYTHON_VERSION=3.11
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
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

	LDFLAGS+=" -Wl,--no-as-needed -lpython${TERMUX_PYTHON_VERSION}"
}

termux_step_make() {
	:
}

termux_step_make_install() {
	export CARGO_BUILD_TARGET=${CARGO_TARGET_NAME}
	export PYO3_CROSS_LIB_DIR=$TERMUX_PREFIX/lib
	export PYTHONPATH=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages

	export RUSTFLAGS="-C link-args=-L$TERMUX_PREFIX/lib $RUSTFLAGS"

	build-python -m maturin build --release --skip-auditwheel --target $CARGO_BUILD_TARGET

	# Fix wheel name for arm
	if [ "$TERMUX_ARCH" = "arm" ]; then
		mv ./target/wheels/pydantic_core-$TERMUX_PKG_VERSION-cp311-cp311-linux_armv7l.whl \
			./target/wheels/pydantic_core-$TERMUX_PKG_VERSION-py311-none-any.whl
	fi

	pip install --no-deps ./target/wheels/*.whl --prefix $TERMUX_PREFIX

	# Fix wheel name for arm
	if [ "$TERMUX_ARCH" = "arm" ]; then
		mv ./target/wheels/pydantic_core-$TERMUX_PKG_VERSION-py311-none-any.whl \
			./target/wheels/pydantic_core-$TERMUX_PKG_VERSION-cp311-cp311-linux_armv7l.whl
	fi
}
