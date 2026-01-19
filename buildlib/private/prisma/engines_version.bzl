"""Repository rule to store the prisma engines version from a pnpm lock."""

load("@bazel_lib//lib:repo_utils.bzl", "repo_utils")

def _load_pnpm_lock(ctx):
    """Loads a pnpm lockfile as a dictionary."""

    pnpm_lock_path = ctx.path(ctx.attr.pnpm_lock)
    ctx.watch(pnpm_lock_path)

    yq_path = str(ctx.path(Label("@yq_{}//:yq".format(repo_utils.platform(ctx)))))

    yq_args = [
        yq_path,
        str(pnpm_lock_path),
        "-o=json",
    ]

    result = ctx.execute(yq_args)

    if result.return_code:
        fail("failed to parse pnpm lock file with yq. " +
             "'{}' exited with {}: \nSTDOUT:\n{}\nSTDERR:\n{}".format(
                 " ".join(yq_args),
                 result.return_code,
                 result.stdout,
                 result.stderr,
             ))

    return json.decode(result.stdout)

def _find_transitive_dependency(snapshots, start_name, start_version, needle_name):
    """Find the version of needle_name in the transitive dependencies of package start_name@start_version.

    Fails if the package with name needle_name is not in the transitive dependencies of start_name@start_version.

    Implementation note: This function does a BFS-style tree traversal: starlark does not support
    recursion nor while loops. Therefore, we have to resort to:
    - Using a queue to track our traversal state.
    - Use a for loop with a high iteration limit instead of a while loop.

    Args:
      snapshots: pnpm lockfile snapshots.
      start_name: name of package to take transitive dependencies of.
      start_version: version of package to transitive dependencies of.
      needle_name: Name of package to look for.
    """

    queue = [(start_name, start_version)]

    max_iters = 100

    for _ in range(0, max_iters):
        if not queue:
            # We have traversed all transitive dependencies.
            fail("couldn't find {} as transitive dependency of {}@{}".format(
                needle_name,
                start_name,
                start_version,
            ))

        name, version = queue.pop()
        if name == needle_name:
            return version

        snapshot = snapshots["{}@{}".format(name, version)]
        queue.extend(snapshot.get("dependencies", {}).items())

    # We have exhausted the iteration limit. This means either of:
    # - The transitive dependency tree of prisma is too big.
    #   Fix: Increase the iteration limit.
    # - There are circular dependencies.
    #   Fix: Build proper BFS (keep track of nodes we have already visited).
    fail("couldn't find {} as transitive dependency of {}@{} after {} iterations".format(
        needle_name,
        start_name,
        start_version,
        max_iters,
    ))

def _get_prisma_engines_version(pnpm_lock):
    """Find and extract the engine version (commit SHA) from the @prisma/engines-version package."""

    lockfile_version = pnpm_lock.get("lockfileVersion")
    if lockfile_version != "9.0":
        fail("Only pnpm lockfile version 9 is supported, got %s" % lockfile_version)

    prisma = pnpm_lock \
        .get("importers", {}) \
        .get(".", {}) \
        .get("devDependencies", {}) \
        .get("prisma")

    if prisma == None:
        # empty string as sentinel is safe, since we only have 40 char SHAs otherwise
        return ""

    raw_version = _find_transitive_dependency(
        pnpm_lock.get("snapshots", {}),
        "prisma",
        prisma["version"],
        "@prisma/engines-version",
    )

    # Version SHA is in build metadata:
    # 4.12.0-34.b36012d6e9bd4f7ff6b13fa02556b753d8bc9094
    version = raw_version.split(".")[-1]

    if len(version) != 40:
        fail("expected 40 char SHA for prisma engines version, got %s" % raw_version)

    return version

def _engines_version_impl(ctx):
    lock = _load_pnpm_lock(ctx)
    version = _get_prisma_engines_version(lock)
    ctx.file("version.txt", content = version)
    ctx.file("BUILD", content = """exports_files(["version.txt"])""")

engines_version = repository_rule(
    local = True,
    implementation = _engines_version_impl,
    attrs = {
        "pnpm_lock": attr.label(
            mandatory = True,
            allow_single_file = [".yaml"],
        ),
    },
)
