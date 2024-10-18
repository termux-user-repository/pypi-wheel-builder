: "${TUR_WHEEL_DIR:="dist"}"
: "${TUR_AUTO_BUILD_WHEEL:=true}"
: "${TUR_AUTO_AUDIT_WHEEL:=false}"
: "${TUR_AUTO_ELF_CLEAN_WHEEL:=true}"
: "${TUR_AUDIT_WHEEL_NO_LIBS:=false}"
: "${TUR_PACKAGE_WHEEL_LICENSE:=true}"
: "${TUR_LIB_LICENSE_JSON:=""}"

tur_install_wheel_license() {
	return
}

tur_update_record_file_of_wheel() {
	local filepath="$(realpath $1)"
	local filename="$(basename $filepath)"

	# Run script to update RECORD file
	build-python $TERMUX_SCRIPTDIR/common-files/audit-and-update-record-for-wheel.py \
		-v $filepath

	# Override the wheel
	mv wheelhouse/$filename $filepath
}

tur_audit_and_repair_wheel() {
	local filepath="$(realpath $1)"
	local filename="$(basename $filepath)"

	# Make sure patchelf is installed
	env -i PATH="$PATH" sudo apt update
	env -i PATH="$PATH" sudo apt install -y patchelf

	# Run script to package libs
	build-python $TERMUX_SCRIPTDIR/common-files/audit-and-repair-wheel.py \
		-v --no-update-tags --lib-sdir="-libs" $filepath

	# Override the wheel
	mv wheelhouse/$filename $filepath
}

tur_check_libs_and_licenses_for_wheel() {
	local filepath="$(realpath $1)"
	local filename="$(basename $filepath)"

	# Run script to check the libs and licenses
	local _args="--lib-sdir=-libs"
	if [ "$TUR_AUDIT_WHEEL_NO_LIBS" != "false" ]; then
		_args+=" --ensure-no-libs"
	fi
	if [ "$TUR_LIB_LICENSE_JSON" != "" ]; then
		_args+=" --check-libs --check-licenses --json $TUR_LIB_LICENSE_JSON"
	elif [ "$TUR_AUDIT_WHEEL_NO_LIBS" == "false" ]; then
		termux_error_exit "Must check libs and licenses after install"
	fi
	build-python $TERMUX_SCRIPTDIR/common-files/audit-and-update-record-for-wheel.py \
		-v $_args $filepath
}

tur_package_wheel_license() {
	local filepath="$(realpath $1)"
	local filename="$(basename $filepath)"
	local whl_name="$(echo $filename | cut -d'-' -f1)"

	# Make a workspace and enter it
	local work_dir="$(mktemp -d)"
	pushd $work_dir

	# Wheel file is actually a zip file, unzip it first.
	unzip -q $filepath

	# Run package license
	mkdir -p "$whl_name-licenses"
	pushd "$whl_name-licenses"
	tur_install_wheel_license
	popd # $whl_name-licenses

	# Re-zip the file
	zip -q -r $filepath *

	# Clean up the workspace
	popd # $work_dir
	rm -rf $work_dir

	# Update RECORD file
	tur_update_record_file_of_wheel $filepath
}

tur_elf_cleaner_for_wheel() {
	local filepath="$(realpath $1)"
	local filename="$(basename $filepath)"

	# Make a workspace and enter it
	local work_dir="$(mktemp -d)"
	pushd $work_dir

	# Wheel file is actually a zip file, unzip it first.
	unzip -q $filepath

	# Run elf-cleaner in the workspace
	find . -type f -print0 | xargs -r -0 \
			"$TERMUX_ELF_CLEANER" --api-level $TERMUX_PKG_API_LEVEL

	# Re-zip the file
	zip -q -r $filepath *

	# Clean up the workspace
	popd # $work_dir
	rm -rf $work_dir

	# Update RECORD file
	tur_update_record_file_of_wheel $filepath
}

tur_build_wheel() {
	pushd $TERMUX_PKG_BUILDDIR

	# Build wheel if needed
	if [ "$TUR_AUTO_BUILD_WHEEL" != "false" ]; then
		pip install wheel
		python setup.py bdist_wheel
	fi

	# Install auditwheel for build-pip
	build-pip install 'auditwheel<6'

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
			tur_audit_and_repair_wheel $_whl
		fi

		# Package license if needed
		if [ "$TUR_PACKAGE_WHEEL_LICENSE" != "false" ]; then
			tur_package_wheel_license $_whl
		fi

		# Run elf-cleaner for wheel if needed
		if [ "$TUR_AUTO_ELF_CLEAN_WHEEL" != "false" ]; then
			tur_elf_cleaner_for_wheel $_whl
		fi

		# Finally, check libs and licenses if needed, and update RECORD file
		tur_check_libs_and_licenses_for_wheel $_whl
	done
	shopt -u nullglob

	# Copy wheels to output
	cp $TUR_WHEEL_DIR/*.whl $TERMUX_SCRIPTDIR/output/
	popd # $TERMUX_PKG_BUILDDIR
}

termux_step_post_massage() {
	tur_build_wheel
}
