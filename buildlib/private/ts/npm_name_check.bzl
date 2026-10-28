"""Validation for npm package names used in esm_node_modules."""

_VALID_PKG_CHARS = {c: True for c in "abcdefghijklmnopqrstuvwxyz0123456789._-".elems()}
_VALID_START_CHARS = {c: True for c in "abcdefghijklmnopqrstuvwxyz0123456789".elems()}

def _is_valid_segment(segment):
    if len(segment) == 0 or segment[0] not in _VALID_START_CHARS:
        return False
    for c in segment.elems():
        if c not in _VALID_PKG_CHARS:
            return False
    return True

def _is_well_behaved_npm_name(name):
    if len(name) == 0 or len(name) > 120:
        return False
    if name.startswith("@"):
        slash_idx = name.find("/")
        if slash_idx < 0:
            return False
        return _is_valid_segment(name[1:slash_idx]) and _is_valid_segment(name[slash_idx + 1:])
    return _is_valid_segment(name)

def check_is_well_behaved_npm_name(name):
    """Fails if name is not a well-behaved npm package name.

    Args:
      name: npm package name string to validate.
    """
    if not _is_well_behaved_npm_name(name):
        fail(
            "esm_node_modules entry '{}' is not a well-behaved npm package name. ".format(name) +
            "Only lowercase alphanumeric characters, hyphens, dots, and underscores are allowed. " +
            "Scoped packages must use @scope/package format. Maximum length is 120 characters.",
        )
