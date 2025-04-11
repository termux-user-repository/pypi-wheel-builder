TERMUX_PKG_HOMEPAGE=https://github.com/pola-rs/polars
TERMUX_PKG_DESCRIPTION="Dataframes powered by a multithreaded, vectorized query engine, written in Rust"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="1.27.1"
TERMUX_PKG_SRCURL=https://github.com/pola-rs/polars/releases/download/py-$TERMUX_PKG_VERSION/polars-$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=94fcb0216b56cd0594aa777db1760a41ad0dfffed90d2ca446cf9294d2e97f02
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libc++, python"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel"
TERMUX_PKG_PYTHON_BUILD_DEPS="maturin"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_UPDATE_VERSION_REGEXP="\d+\.\d+\.\d+"
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

# Polars doesn't officially support 32-bit Python.
# See https://github.com/pola-rs/polars/issues/10460
TERMUX_PKG_BLACKLISTED_ARCHES="arm, i686"

TERMUX_PYTHON_VERSION=3.12
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true
TUR_AUTO_BUILD_WHEEL=false
TUR_WHEEL_DIR="target/wheels"

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_pkg_auto_update() {
	# Get latest release tag:
	local api_url="https://api.github.com/repos/pola-rs/polars/git/refs/tags"
	local latest_refs_tags=$(curl -s "${api_url}" | jq .[].ref | grep -oP py-${TERMUX_PKG_UPDATE_VERSION_REGEXP} | sort -V)
	if [[ -z "${latest_refs_tags}" ]]; then
		echo "WARN: Unable to get latest refs tags from upstream. Try again later." >&2
		return
	fi

	local latest_version="$(echo "${latest_refs_tags}" | tail -n1 | cut -c 4-)"
	if [[ "${latest_version}" == "${TERMUX_PKG_VERSION}" ]]; then
		echo "INFO: No update needed. Already at version '${TERMUX_PKG_VERSION}'."
		return
	fi

	termux_pkg_upgrade_version "${latest_version}"
}

termux_step_pre_configure() {
	termux_setup_cmake
	termux_setup_rust

	: "${CARGO_HOME:=$HOME/.cargo}"
	export CARGO_HOME

	cargo fetch --target "${CARGO_TARGET_NAME}"

	# Dummy CMake toolchain file to workaround build error:
	# CMake Error at /home/builder/.termux-build/_cache/cmake-3.30.3/share/cmake-3.30/Modules/Platform/Android-Determine.cmake:218 (message):
	# Android: Neither the NDK or a standalone toolchain was found.
	export TARGET_CMAKE_TOOLCHAIN_FILE="${TERMUX_PKG_BUILDDIR}/android.toolchain.cmake"
	touch "${TERMUX_PKG_BUILDDIR}/android.toolchain.cmake"

	cargo vendor
	patch --silent -p1 \
		-d ./vendor/arboard/ \
		< "$TERMUX_PKG_BUILDER_DIR"/arboard-dummy-platform.diff

	sed -i 's|^\(\[patch\.crates-io\]\)$|\1\narboard = { path = "\./vendor/arboard" }|g' \
		Cargo.toml

	LDFLAGS+=" -Wl,--no-as-needed,-lpython${TERMUX_PYTHON_VERSION},--as-needed"
}

termux_step_make() {
	export CARGO_BUILD_TARGET=${CARGO_TARGET_NAME}
	export PYO3_CROSS_LIB_DIR=$TERMUX_PREFIX/lib
	export PYTHONPATH=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages

	build-python -m maturin build \
				--target $CARGO_BUILD_TARGET \
				--release --skip-auditwheel \
				--interpreter python${TERMUX_PYTHON_VERSION}

	# Fix wheel name, although it it built with tag `cp38-abi3`, but it is linked against `python3.x.so`
	# so it will not work on other pythons.
	local _pyver="${TERMUX_PYTHON_VERSION/./}"
	mv ./target/wheels/polars-$TERMUX_PKG_VERSION-cp39-abi3-linux_$TERMUX_ARCH.whl \
		./target/wheels/polars-$TERMUX_PKG_VERSION-cp$_pyver-cp$_pyver-linux_$TERMUX_ARCH.whl
}

termux_step_make_install() {
	pip install --no-deps ./target/wheels/*.whl --prefix $TERMUX_PREFIX
}

termux_step_post_make_install() {
	# This is not necessary, and may cause file conflict
	rm -f $PYTHONPATH/rust-toolchain.toml

	# Remove the vendor sources to save space
	rm -rf "$TERMUX_PKG_SRCDIR"/vendor
}

termux_step_post_massage() {
	tur_build_wheel
}
