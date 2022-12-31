TERMUX_PKG_HOMEPAGE=https://cairographics.org/pycairo
TERMUX_PKG_DESCRIPTION="This package contains modules that allow you to use the Cairo vector graphics library in Python3 programs."
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_MAINTAINER="@fervi"
TERMUX_PKG_VERSION="1.23.0"
TERMUX_PKG_SRCURL=https://github.com/pygobject/pycairo/releases/download/v${TERMUX_PKG_VERSION}/pycairo-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=9b61ac818723adc04367301317eb2e814a83522f07bbd1f409af0dada463c44c
TERMUX_PKG_DEPENDS="python, libcairo"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_BUILD_IN_SRC=true

tur_elf_cleaner_for_wheel() {
	local filename="$(realpath $1)"

	# Make a workspace and enter it
	local work_dir="$(mktemp -d)"
	pushd $work_dir

	# Wheel file is actually a zip file, unzip it first.
	unzip -q $filename

	# Run elf-cleaner in the workspace
	find . -type f -print0 | xargs -r -0 \
			"$TERMUX_ELF_CLEANER" --api-level $TERMUX_PKG_API_LEVEL

	# Re-zip the file
	zip -q -r $filename *

	# Clean up the workspace
	popd
	rm -rf $work_dir
}

termux_step_configure() {
	_PYTHON_VERSION=$(. $TERMUX_SCRIPTDIR/packages/python/build.sh; echo $_MAJOR_VERSION)
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

termux_step_post_massage() {
	pushd $TERMUX_PKG_BUILDDIR
	pip install wheel
	python setup.py bdist_wheel

	# Run elf-cleaner for wheels
	shopt -s nullglob
	local _whl
	for _whl in ./dist/*.whl; do
		tur_elf_cleaner_for_wheel $_whl
	done
	shopt -u nullglob

	cp dist/*.whl $TERMUX_SCRIPTDIR/output/
	popd
}
