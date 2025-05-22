TERMUX_PKG_HOMEPAGE=https://onnxruntime.ai/
TERMUX_PKG_DESCRIPTION="Cross-platform, high performance ML inferencing and training accelerator"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.22.0"
TERMUX_PKG_SRCURL=git+https://github.com/microsoft/onnxruntime
TERMUX_PKG_DEPENDS="libc++, python"
TERMUX_PKG_BUILD_DEPENDS="python-numpy"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, build, packaging"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Donnxruntime_ENABLE_PYTHON=ON
-Donnxruntime_BUILD_SHARED_LIB=ON
-DPYBIND11_USE_CROSSCOMPILING=TRUE
-Donnxruntime_USE_NNAPI_BUILTIN=ON
-Donnxruntime_USE_XNNPACK=ON
"

TERMUX_PYTHON_VERSION=3.12
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true
TUR_AUTO_BUILD_WHEEL=false

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

_setup_protobuf() {
	local _PROTOBUF_VERSION=21.12
	local _PROTOBUF_ZIP=protoc-$_PROTOBUF_VERSION-linux-x86_64.zip
	local _PROTOBUF_FOLDER=${TERMUX_PKG_CACHEDIR}/protobuf-${_PROTOBUF_VERSION}

	if [ ! -d "$_PROTOBUF_FOLDER" ]; then
		termux_download \
			https://github.com/protocolbuffers/protobuf/releases/download/v$_PROTOBUF_VERSION/$_PROTOBUF_ZIP \
			$TERMUX_PKG_TMPDIR/$_PROTOBUF_ZIP \
			3a4c1e5f2516c639d3079b1586e703fc7bcfa2136d58bda24d1d54f949c315e8

		rm -Rf "$TERMUX_PKG_TMPDIR/protoc-$_PROTOBUF_VERSION"
		unzip $TERMUX_PKG_TMPDIR/$_PROTOBUF_ZIP -d $TERMUX_PKG_TMPDIR/protobuf-$_PROTOBUF_VERSION
		mv "$TERMUX_PKG_TMPDIR/protobuf-$_PROTOBUF_VERSION" \
			$_PROTOBUF_FOLDER
	fi

	export PATH="$_PROTOBUF_FOLDER/bin/:$PATH"
}

termux_step_pre_configure() {
	termux_setup_cmake
	termux_setup_ninja
	_setup_protobuf

	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DPYTHON_EXECUTABLE=$(command -v python3)"
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DONNX_CUSTOM_PROTOC_EXECUTABLE=$(command -v protoc)"
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DPython_NumPy_INCLUDE_DIR=$PYTHON_SITE_PKG/numpy/_core/include"

	local TERMUX_PKG_SRCDIR_SAVE="$TERMUX_PKG_SRCDIR"
	TERMUX_PKG_SRCDIR+="/cmake"
	termux_step_configure_cmake
	TERMUX_PKG_SRCDIR="$TERMUX_PKG_SRCDIR_SAVE"

	cmake --build . -j $TERMUX_PKG_MAKE_PROCESSES
}

termux_step_make() {
	python -m build --wheel --no-isolation
}

termux_step_make_install() {
	local _pyver="${TERMUX_PYTHON_VERSION//./}"
	local _wheel="onnxruntime-${TERMUX_PKG_VERSION}-cp${_pyver}-cp${_pyver}-linux_${TERMUX_ARCH}.whl"
	pip install --no-deps --prefix="$TERMUX_PREFIX" "$TERMUX_PKG_SRCDIR/dist/${_wheel}"
}
