"""write_setup_source_file macro."""

load("@bazel_lib//lib:write_source_files.bzl", "write_source_file")

def write_setup_source_file(name, in_file, out_file, update_targets):
    """Write a setup source file.

    Invokes write_source_file, but also
    - adds the target to update_targets
    - adds suggested_update_target

    This is to link up the top-level write_source_files rule which will allow to update *all* setup files at once.

    Args:
      name: Name of the rule.
      in_file: file with content to write
      out_file: file to write to.
      update_targets: List of update targets. **WILL BE MUTATED**.
    """

    write_source_file(
        name = name,
        in_file = in_file,
        out_file = out_file,
        suggested_update_target = "//:buildlib_setup.write",
    )

    update_targets.append(name)
