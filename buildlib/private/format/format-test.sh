export BUILD_WORKSPACE_DIRECTORY="$(dirname "$(realpath ${FILE_IN_WORKSPACE})")"

$DH_FORMAT_SCRIPT --check
