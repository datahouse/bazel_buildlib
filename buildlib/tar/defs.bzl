"""Concenience rules / macro to ease use of Aspect Bazel Lib's tar / mtree_spec."""

load("//private/tar:tar.bzl", _mtree_replace_prefix = "mtree_replace_prefix", _mtree_spec = "mtree_spec", _tar_auto_mtree = "tar_auto_mtree")

mtree_replace_prefix = _mtree_replace_prefix
mtree_spec = _mtree_spec
tar_auto_mtree = _tar_auto_mtree
