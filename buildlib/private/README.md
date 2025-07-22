# Implementation of dh_buildlib

This file hosts implementation documentation.

The headings are "tags" we use at sites that need explanation.

## [sym-macro-use-site-label-res]

We need to keep the default labels as strings, because we want them to be
resolved in the calling repository. This is why we cannot use the `default`
param of the `attr.label` function: It would resolve the label at definition
site (buildlib).
