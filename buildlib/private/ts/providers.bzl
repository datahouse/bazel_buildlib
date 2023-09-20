"""providers for typescript."""

TsLibraryInfo = provider(
    doc = """Provider for buildlib ts_library targets (buildlib internal)""",
    fields = {
        "uses_dom": "Whether the library uses the DOM.",
    },
)
