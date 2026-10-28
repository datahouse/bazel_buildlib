"""Utilities to deal with OCI images."""

def get_oci_dir(image_target):
    """Interprets image_target as OCI Image.

    Args:
      image_target: The target to extract the File from.

    Returns:
      A single File (which is a directory) or fails.
    """

    files = image_target.files.to_list()
    if len(files) != 1:
        fail("{}: expected 1 output file, got {}".format(image_target.label, files))

    file = files[0]

    if not file.is_directory:
        fail("{}: expected directory, got {}".format(image_target.label, file))

    return file
