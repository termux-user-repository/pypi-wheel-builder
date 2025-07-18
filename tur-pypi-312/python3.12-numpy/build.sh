TERMUX_PKG_HOMEPAGE=https://numpy.org/
TERMUX_PKG_DESCRIPTION="The fundamental package for scientific computing with Python"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="2.3.1"
TERMUX_PKG_SRCURL=git+https://github.com/numpy/numpy
TERMUX_PKG_DEPENDS="libc++, libopenblas, python"
TERMUX_PKG_PYTHON_COMMON_DEPS="wheel, 'Cython>=0.29.34,<3.1', 'meson-python>=0.15.0,<0.16.0', build"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

TERMUX_MESON_WHEEL_CROSSFILE="$TERMUX_PKG_TMPDIR/wheel-cross-file.txt"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--cross-file $TERMUX_MESON_WHEEL_CROSSFILE
"

TERMUX_PKG_RM_AFTER_INSTALL="
bin/
"

TERMUX_PYTHON_VERSION=3.12
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUTO_BUILD_WHEEL=false
TUR_WHEEL_DIR="../src/dist"
TUR_LIB_LICENSE_JSON="$TERMUX_PKG_BUILDER_DIR/licenses.json"

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_pre_configure() {
	LDFLAGS+=" -lm"
}

termux_step_configure() {
	termux_setup_meson

	cp -f $TERMUX_MESON_CROSSFILE $TERMUX_MESON_WHEEL_CROSSFILE
	sed -i 's|^\(\[binaries\]\)$|\1\npython = '\'$(command -v python)\''|g' \
		$TERMUX_MESON_WHEEL_CROSSFILE
	sed -i 's|^\(\[properties\]\)$|\1\nnumpy-include-dir = '\'$PYTHON_SITE_PKG/numpy/_core/include\''|g' \
		$TERMUX_MESON_WHEEL_CROSSFILE

	local _longdouble_format=""
	if [ $TERMUX_ARCH_BITS = 32 ]; then
		_longdouble_format="IEEE_DOUBLE_LE"
	else
		_longdouble_format="IEEE_QUAD_LE"
	fi
	sed -i 's|^\(\[properties\]\)$|\1\nlongdouble_format = '\'$_longdouble_format\''|g' \
		$TERMUX_MESON_WHEEL_CROSSFILE

	local _meson_buildtype="minsize"
	local _meson_stripflag="--strip"
	if [ "$TERMUX_DEBUG_BUILD" = "true" ]; then
		_meson_buildtype="debug"
		_meson_stripflag=
	fi

	local _custom_meson="build-python $TERMUX_PKG_SRCDIR/vendored-meson/meson/meson.py"
	CC=gcc CXX=g++ CFLAGS= CXXFLAGS= CPPFLAGS= LDFLAGS= $_custom_meson \
		$TERMUX_PKG_SRCDIR \
		$TERMUX_PKG_BUILDDIR \
		--cross-file $TERMUX_MESON_CROSSFILE \
		--prefix $TERMUX_PREFIX \
		--libdir lib \
		--buildtype ${_meson_buildtype} \
		${_meson_stripflag} \
		$TERMUX_PKG_EXTRA_CONFIGURE_ARGS
}

termux_step_make() {
	pushd $TERMUX_PKG_SRCDIR
	python -m build -w -n -x --config-setting builddir=$TERMUX_PKG_BUILDDIR .
	popd
}

termux_step_make_install() {
	local _pyv="${TERMUX_PYTHON_VERSION/./}"
	local _whl="numpy-$TERMUX_PKG_VERSION-cp$_pyv-cp$_pyv-linux_$TERMUX_ARCH.whl"
	pip install --no-deps --prefix=$TERMUX_PREFIX --force-reinstall $TERMUX_PKG_SRCDIR/dist/$_whl
}

tur_install_wheel_license() {
	# Install the license of libopenblas
	cp $TERMUX_PREFIX/share/doc/libopenblas/copyright libopenblas-LICENSE
}
