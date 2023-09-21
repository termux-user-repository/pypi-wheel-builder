TERMUX_PKG_HOMEPAGE=https://cairographics.org/pycairo
TERMUX_PKG_DESCRIPTION="This package contains modules that allow you to use the Cairo vector graphics library in Python3 programs."
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_MAINTAINER="@fervi"
TERMUX_PKG_VERSION="1.23.0"
TERMUX_PKG_SRCURL=https://github.com/pygobject/pycairo/releases/download/v${TERMUX_PKG_VERSION}/pycairo-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=9b61ac818723adc04367301317eb2e814a83522f07bbd1f409af0dada463c44c
TERMUX_PKG_DEPENDS="python3.10, libcairo"
TERMUX_PKG_BUILD_IN_SRC=true

source $TERMUX_SCRIPTDIR/common-files/tur_elf_cleaner_for_wheel.sh

termux_step_configure() {
	_PYTHON_VERSION=3.10
	termux_setup_python_crossenv
	pushd $TERMUX_PYTHON_CROSSENV_SRCDIR
	_CROSSENV_PREFIX=$TERMUX_PKG_BUILDDIR/python-crossenv-prefix
	python${_PYTHON_VERSION} -m crossenv \
		$TERMUX_PREFIX/bin/python${_PYTHON_VERSION} \
		${_CROSSENV_PREFIX}
	popd
	. ${_CROSSENV_PREFIX}/bin/activate

	LDFLAGS+=" -lpython${_PYTHON_VERSION}"
	build-pip install wheel
}

termux_step_make_install() {
	export PYTHONPATH=$TERMUX_PREFIX/lib/python${_PYTHON_VERSION}/site-packages
	pip install --no-deps . --prefix $TERMUX_PREFIX
}
