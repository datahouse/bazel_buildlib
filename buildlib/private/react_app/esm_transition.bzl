"""ES module transition (to get transpiled code in ES module, not commonjs)."""

def _esm_transition_impl(_settings, _attr):
    return {
        "//private/ts:module": "es2020",
    }

esm_transition = transition(
    implementation = _esm_transition_impl,
    inputs = [],
    outputs = [
        "//private/ts:module",
    ],
)
