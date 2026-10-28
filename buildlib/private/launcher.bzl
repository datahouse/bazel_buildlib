"""Helper for creating shell forwarding launcher scripts."""

load("@bazel_skylib//lib:shell.bzl", "shell")

def create_launcher(ctx, executable, fixed_args = []):
    """Create a shell launcher that forwards to an executable with fixed_args.

    Args:
      ctx: Rule context.
      executable: Target providing an executable (i.e. a ctx.attr.* value).
      fixed_args: String arguments passed before "$@".

    Returns:
      struct(executable, runfiles) - callers should merge additional runfiles as needed.
    """

    exe_file = executable.files_to_run.executable
    if exe_file == None:
        fail("create_launcher: 'executable' target %s does not provide an executable" % executable.label)

    resolved_args = " ".join([shell.quote(a) for a in [exe_file.short_path] + fixed_args])
    content = "#!/bin/sh\nexec %s \"$@\"\n" % resolved_args

    launcher = ctx.actions.declare_file(ctx.label.name + ".launcher")
    ctx.actions.write(
        output = launcher,
        content = content,
        is_executable = True,
    )

    runfiles = ctx.runfiles(files = [launcher]).merge(
        executable.default_runfiles,
    )

    return struct(
        executable = launcher,
        runfiles = runfiles,
    )
