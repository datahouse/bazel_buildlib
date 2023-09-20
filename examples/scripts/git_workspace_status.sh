#! /bin/sh

# A workspace status script for stamping with git.
#
# A normal project does not need this, but it is here as an
# example.
#
# You can use this by adding the following to .bazelrc
# ```
# build --workspace_status_command git_workspace_status.sh
# ```

echo "STABLE_GIT_COMMIT $(git rev-parse HEAD)"
echo "STABLE_GIT_REPO_URL $(git config --get remote.origin.url)"

# The use of the git url is arguably an abuse.
# But for local builds, this is good enough.
echo "STABLE_WEB_REPO_URL $(git config --get remote.origin.url)"
