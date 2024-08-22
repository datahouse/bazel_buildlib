if [ -z "$DH_BUILDLIB_FORMAT_CHECK_DIR" ]; then
    echo "DH_BUILDLIB_FORMAT_CHECK_DIR not set. No check performed."
    exit 0
fi

export BUILD_WORKSPACE_DIRECTORY="$DH_BUILDLIB_FORMAT_CHECK_DIR"

$DH_FORMAT_SCRIPT --check
