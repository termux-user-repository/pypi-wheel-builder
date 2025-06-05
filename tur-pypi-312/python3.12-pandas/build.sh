TERMUX_PKG_HOMEPAGE=https://pandas.pydata.org/
TERMUX_PKG_DESCRIPTION="Powerful Python data analysis toolkit"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_MAINTAINER="@termux-user-repository"
TERMUX_PKG_VERSION="2.3.0"
TERMUX_PKG_SRCURL=git+https://github.com/pandas-dev/pandas
TERMUX_PKG_SHA256=d8abf9c2bf33cac75b28f32c174c29778414eb249e5e2ccb69b1079b97a8fc66
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libc++, python, python-numpy"
_NUMPY_VERSION=$(. $TERMUX_SCRIPTDIR/packages/python-numpy/build.sh; echo $TERMUX_PKG_VERSION)
TERMUX_PKG_PYTHON_COMMON_DEPS="'Cython==3.0.5', 'numpy==$_NUMPY_VERSION', wheel, versioneer"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

TERMUX_PYTHON_VERSION=3.12
TERMUX_PYTHON_HOME=$TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}
TERMUX_PYTHON_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python${TERMUX_PYTHON_VERSION/./}-crossenv-prefix-$TERMUX_ARCH
TUR_AUTO_AUDIT_WHEEL=true
TUR_AUDIT_WHEEL_NO_LIBS=true
TUR_AUTO_BUILD_WHEEL=false
TUR_PACKAGE_WHEEL_LICENSE=false

source $TERMUX_SCRIPTDIR/common-files/tur_build_wheel.sh

termux_step_pre_configure() {
	CFLAGS="-I$TERMUX_PYTHON_HOME/site-packages/numpy/core/include $CFLAGS"
	CPPFLAGS="-I$TERMUX_PYTHON_HOME/site-packages/numpy/core/include $CPPFLAGS"
	CXXFLAGS="-I$TERMUX_PYTHON_HOME/site-packages/numpy/core/include $CXXFLAGS"
	LDFLAGS+=" -lm"
}

termux_step_configure() {
	:
}

termux_step_make() {
	python setup.py bdist_wheel -vvv
}

termux_step_make_install() {
	pip install ./dist/*.whl --no-deps --prefix=$PREFIX -vvv
}
