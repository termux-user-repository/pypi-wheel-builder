TERMUX_PKG_HOMEPAGE=https://github.com/pydantic/pydantic-core
TERMUX_PKG_DESCRIPTION="Core validation logic for pydantic written in rust"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="2.33.1"
TERMUX_PKG_SRCURL=https://github.com/pydantic/pydantic-core/archive/refs/tags/v$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=02f956a1302a2da4d736d08f78b2be9642e4a2a342bc442f30c955e5bb1ac07e
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libc++, python"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, 'typing-extensions==4.6.0'"
TERMUX_PKG_PYTHON_BUILD_DEPS="maturin"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

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

	local _pyver="${TERMUX_PYTHON_VERSION/./}"
	# Fix wheel name for arm
	if [ "$TERMUX_ARCH" = "arm" ]; then
		mv ./target/wheels/pydantic_core-$TERMUX_PKG_VERSION-cp$_pyver-cp$_pyver-linux_armv7l.whl \
			./target/wheels/pydantic_core-$TERMUX_PKG_VERSION-py$_pyver-none-any.whl
	fi

	pip install --no-deps ./target/wheels/*.whl --prefix $TERMUX_PREFIX

	# Fix wheel name for arm
	if [ "$TERMUX_ARCH" = "arm" ]; then
		mv ./target/wheels/pydantic_core-$TERMUX_PKG_VERSION-py$_pyver-none-any.whl \
			./target/wheels/pydantic_core-$TERMUX_PKG_VERSION-cp$_pyver-cp$_pyver-linux_armv7l.whl
	fi
}
