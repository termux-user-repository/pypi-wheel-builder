: "${TUR_AUTO_BUILD_WHEEL:=true}"
: "${TUR_AUTO_AUDIT_WHEEL:=false}"

tur_audit_wheel() {
	local filepath="$(realpath $1)"
	local filename="$(basename $filepath)"

	# Make sure patchelf is installed
	env -i PATH="$PATH" sudo apt update
	env -i PATH="$PATH" sudo apt install -y patchelf

	# Install auditwheel for build-pip
	build-pip install 'auditwheel<6'
	build-python $TERMUX_SCRIPTDIR/common-files/audit-and-repair-wheel.py \
		-v --no-update-tags --lib-sdir="-libs" $filepath

	# Override the wheel
	mv wheelhouse/$filename $filepath
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

tur_build_wheel() {
	: "${TUR_WHEEL_DIR:="dist"}"
	pushd $TERMUX_PKG_BUILDDIR

	# Build wheel if needed
	if [ "$TUR_AUTO_BUILD_WHEEL" != "false" ]; then
		pip install wheel
		python setup.py bdist_wheel
	fi

	shopt -s nullglob
	local _whl _whl_name _whl_version
	for _whl in $TERMUX_PKG_BUILDDIR/$TUR_WHEEL_DIR/*.whl; do
		# Check wheel version
		# The python wheel is constructed with `{name}-{version}-{platform}-{abi}-{tag}`
		_whl_name="$(basename $_whl)"
		_whl_version="$(echo $_whl_name | cut -d'-' -f2)"
		if [ "$_whl_version" != "$TERMUX_PKG_VERSION" ]; then
			termux_error_exit "Version mismatch: Expected $TERMUX_PKG_VERSION, got $_whl_version."
		fi

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

termux_step_post_massage() {
	tur_build_wheel
}
