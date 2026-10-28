# Corepack bootstrapping

In CI, we need corepack to install pnpm.
The node image does not ship with corepack (starting Node 25).
Therefore, we install corepack with npm (**not** pnpm).

This directory holds the package.json / package-lock.json for this installation.
