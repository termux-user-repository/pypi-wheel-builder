TERMUX_PKG_HOMEPAGE=https://github.com/pydantic/pydantic-core
TERMUX_PKG_DESCRIPTION="Core validation logic for pydantic written in rust"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="2.32.0"
TERMUX_PKG_SRCURL=https://github.com/pydantic/pydantic-core/archive/refs/tags/v$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=51dcc21d378c2622aa8538bb6dfcfb01595f297e59a009b375eacac47780a52e
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libc++, python3.11"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, 'typing-extensions==4.6.0'"
TERMUX_PKG_PYTHON_BUILD_DEPS="maturin"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

TERMUX_PYTHON_VERSION=3.11
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
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

	local env_host=$(printf $CARGO_TARGET_NAME | tr a-z A-Z | sed s/-/_/g)
	export CARGO_TARGET_${env_host}_RUSTFLAGS+=" -C link-arg=-L$TERMUX_PREFIX/lib"

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
