"""Rules to hack around things.

They really shouldn't be here, but we haven't found a better solution.

If you use any of these, expect to be asked to migrate quickly, once a cleaner solution is available.
"""

load("//private/hacks:transpile_esm_to_cjs.bzl", _transpile_esm_to_cjs = "transpile_esm_to_cjs")

transpile_esm_to_cjs = _transpile_esm_to_cjs
