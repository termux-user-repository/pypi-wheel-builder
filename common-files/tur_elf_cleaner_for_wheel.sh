: "${TUR_AUTO_BUILD_WHEEL:=true}"
: "${TUR_AUTO_AUDIT_WHEEL:=false}"

tur_audit_wheel() {
	local filename="$(realpath $1)"

	# Make sure patchelf is installed
	env -i PATH="$PATH" sudo apt update
	env -i PATH="$PATH" sudo apt install -y patchelf

	# Install auditwheel for build-pip
	build-pip install auditwheel
	build-python $TERMUX_SCRIPTDIR/common-files/audit-and-repair-wheel.py \
		-v --no-update-tags --lib-sdir="-libs" $filename

	# Override the wheel
	mv wheelhouse/numpy-1.24.1-cp311-cp311-linux_x86_64.whl $filename
}

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

termux_step_post_massage() {
	: "${TUR_WHEEL_DIR:="dist"}"
	pushd $TERMUX_PKG_BUILDDIR

	# Build wheel if needed
	if [ "$TUR_AUTO_BUILD_WHEEL" != "false" ]; then
		pip install wheel
		python setup.py bdist_wheel
	fi

	shopt -s nullglob
	local _whl
	for _whl in $TERMUX_PKG_BUILDDIR/$TUR_WHEEL_DIR/*.whl; do
		# Audit wheel if needed
		if [ "$TUR_AUTO_AUDIT_WHEEL" != "false" ]; then
			tur_audit_wheel	$_whl
		fi
		# Run elf-cleaner for wheel
		tur_elf_cleaner_for_wheel $_whl
	done
	shopt -u nullglob

	# Copy wheels to output
	cp $TUR_WHEEL_DIR/*.whl $TERMUX_SCRIPTDIR/output/
	popd
}
