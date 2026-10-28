"""Repository rule to store prisma version information from a pnpm lock."""

load("@bazel_lib//lib:repo_utils.bzl", "repo_utils")

def _load_pnpm_lock(ctx):
    """Loads a pnpm lockfile as a dictionary."""

    pnpm_lock_path = ctx.path(ctx.attr.pnpm_lock)
    ctx.watch(pnpm_lock_path)

    yq_path = str(ctx.path(Label("@yq_{}//:yq".format(repo_utils.platform(ctx)))))

    yq_args = [
        yq_path,
        "eval-all",
        # Collect all YAML documents into a single JSON array.
        "[.]",
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

    documents = json.decode(result.stdout)

    # pnpm may prepend an env document (https://pnpm.io/lockfile#when-a-lockfile-has-two-documents),
    # so we take the last one.
    return documents[-1]

def _find_transitive_dependency(snapshots, start_name, start_version, needle_name):
    """Find the version of needle_name in the transitive dependencies of package start_name@start_version.

    Fails if the package with name needle_name is not in the transitive dependencies of start_name@start_version.

    Implementation note: This function does a graph traversal: starlark does not support
    recursion nor while loops. Therefore, we have to resort to:
    - Using a queue to track our traversal state.
    - Use a for loop bounded by the number of snapshots and ensuring a dependency is enqueued exactly once.

    Args:
      snapshots: pnpm lockfile snapshots.
      start_name: name of package to take transitive dependencies of.
      start_version: version of package to transitive dependencies of.
      needle_name: Name of package to look for.
    """

    queue = [(start_name, start_version)]
    visited = {(start_name, start_version): True}

    # We dedupe before push (not on pop) so each package is queued at most once, keeping
    # iterations bounded by the package count rather than the dependency-link count.
    max_iters = len(snapshots) + 1

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
        for dependency in snapshot.get("dependencies", {}).items():
            if dependency not in visited:
                visited[dependency] = True
                queue.append(dependency)

    # Unreachable: if we got here, the queue did not empty within max_iters iterations. That
    # shouldn't happen, since the loop is bounded by the snapshot count and each snapshot is enqueued
    # at most once, so it means our algorithm is wrong.
    fail("exceeded {} iterations while searching for {} under {}@{}\nplease report this as a buildlib bug".format(
        max_iters,
        needle_name,
        start_name,
        start_version,
    ))

def _get_version_info(pnpm_lock):
    """Find and extract prisma version information.

    - engines version (commit SHA) from the @prisma/engines-version package.
    - whether prisma version is >= 7
    """

    lockfile_version = pnpm_lock.get("lockfileVersion")
    if lockfile_version != "9.0":
        fail("Only pnpm lockfile version 9 is supported, got %s" % lockfile_version)

    prisma = pnpm_lock \
        .get("importers", {}) \
        .get(".", {}) \
        .get("devDependencies", {}) \
        .get("prisma")

    if prisma == None:
        # Prisma is not installed.
        return None

    raw_engines_version = _find_transitive_dependency(
        pnpm_lock.get("snapshots", {}),
        "prisma",
        prisma["version"],
        "@prisma/engines-version",
    )

    # Version SHA is in build metadata:
    # 4.12.0-34.b36012d6e9bd4f7ff6b13fa02556b753d8bc9094
    engines_version = raw_engines_version.split(".")[-1]

    if len(engines_version) != 40:
        fail("expected 40 char SHA for prisma engines version, got %s" % raw_engines_version)

    return {
        "engines": engines_version,
        "prisma7_or_above": int(prisma["version"].split(".", 1)[0]) >= 7,
    }

def _version_info_impl(ctx):
    lock = _load_pnpm_lock(ctx)
    info = _get_version_info(lock)
    ctx.file("info.json", content = json.encode(info))
    ctx.file("BUILD", content = """exports_files(["info.json"])""")

    return ctx.repo_metadata(reproducible = True)

version_info = repository_rule(
    local = True,
    implementation = _version_info_impl,
    attrs = {
        "pnpm_lock": attr.label(
            mandatory = True,
            allow_single_file = [".yaml"],
        ),
    },
)
