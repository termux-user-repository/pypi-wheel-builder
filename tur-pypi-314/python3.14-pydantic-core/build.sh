TERMUX_PKG_HOMEPAGE=https://github.com/pydantic/pydantic
TERMUX_PKG_DESCRIPTION="Core validation logic for pydantic written in rust"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="2.48.0"
TERMUX_PKG_SRCURL=https://github.com/pydantic/pydantic/archive/refs/tags/core-v$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=347ea90c7425a1516b5a3516695399922fe57d2b82c3573a7940410c5ea4167d
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libc++, python, python-pip"
TERMUX_PKG_PYTHON_COMMON_BUILD_DEPS="wheel, 'typing-extensions==4.6.0'"
TERMUX_PKG_PYTHON_CROSS_BUILD_DEPS="'maturin<1.13'"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"
TERMUX_PKG_UPDATE_VERSION_SED_REGEXP='s/core-v//'

TERMUX_PYTHON_VERSION=3.14
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TERMUX_PYTHON_CROSSENV_BUILDHOME=$TERMUX_PYTHON_CROSSENV_PREFIX/build/lib/python${TERMUX_PYTHON_VERSION}
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true
TUR_AUTO_BUILD_WHEEL=false
TUR_WHEEL_DIR="target/wheels"

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_pkg_auto_update() {
	# Get latest release tag:
	local api_url="https://api.github.com/repos/pydantic/pydantic/git/refs/tags"
	local latest_refs_tags=$(curl -s "$api_url" | jq -r .[].ref | cut -d'/' -f 3 | grep "core-")
	if [[ -z "${latest_refs_tags}" ]]; then
		echo "WARN: Unable to get latest refs tags from upstream. Try again later." >&2
		return
	fi
	local latest_version="$(echo "${latest_refs_tags}" | sort -V | tail -n1)"
	termux_pkg_upgrade_version "${latest_version}"
}

termux_step_pre_configure() {
	TERMUX_PKG_SRCDIR+="/pydantic-core"
	TERMUX_PKG_BUILDDIR+="/pydantic-core"
}

termux_step_make() {
	termux_setup_rust

	export LDFLAGS+=" -Wl,--no-as-needed -lpython${TERMUX_PYTHON_VERSION}"

	export CARGO_BUILD_TARGET=${CARGO_TARGET_NAME}
	export PYO3_CROSS_PYTHON_VERSION=$TERMUX_PYTHON_VERSION
	export PYO3_CROSS_LIB_DIR=$TERMUX_PREFIX/lib
	export PYTHONPATH=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages
	export ANDROID_API_LEVEL="$TERMUX_PKG_API_LEVEL"

	build-python -m maturin build \
				--target $CARGO_BUILD_TARGET \
				--release --skip-auditwheel \
				--interpreter python${TERMUX_PYTHON_VERSION}
}

termux_step_make_install() {
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
	local pack_name="pydantic_core"
	local pyversion="${TERMUX_PYTHON_VERSION/./}"
	local native_wheel_ext="${TERMUX_PKG_VERSION}-cp${pyversion}-cp${pyversion}-android_${ANDROID_API_LEVEL}_${native_wheel_arch}.whl"
	local cross_wheel_ext="${TERMUX_PKG_VERSION}-cp${pyversion}-none-any.whl"
	local release_whl_ext="${TERMUX_PKG_VERSION}-cp${pyversion}-cp${pyversion}-android_${ANDROID_API_LEVEL}_${native_wheel_arch}.whl"

	local _whl_orig="target/wheels/${pack_name}-${native_wheel_ext}"
	local _whl_dest="target/wheels/${pack_name}-${cross_wheel_ext}"
	local _whl_release="target/wheels/${pack_name}-${release_whl_ext}"
	mv "$_whl_orig" "$_whl_dest"
	pip install --force-reinstall --no-deps --prefix "$TERMUX_PREFIX" "$_whl_dest"
	mv "$_whl_dest" "$_whl_release"
}
