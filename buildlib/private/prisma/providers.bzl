"""Providers for the Prisma subsystem."""

PrismaSchemaInfo = provider(
    doc = """Provider for prisma schema info""",
    fields = {
        "db_type": "Database type (aka provider in prisma)",
        "db_url_env": "Environment variable for db url.",
        "schema": "Prisma schema.",
    },
)

PrismaEnginesInfo = provider(
    doc = "Provider for a set of prisma engines",
    fields = {
        "libquery_engine": "Query engine (lib)",
        "platform": "Prisma platform string",
        "query_engine": "Query engine (bin)",
        "schema_engine": "Schema engine (bin)",
    },
)

PrismaGeneratorInfo = provider(
    doc = "Information about an instance of a prisma generator.",
    fields = {
        "exec_paths": "Additional paths to add to PATH env when running `prisma generate`",
        "generate_deps": "Additional dependencies to run `prisma generate`",
        "target_name": "Name of the generator and the final output directory",
    },
)

PrismaGenerateInfo = provider(
    doc = "Information about a result of prisma generation.",
    fields = {
        "out_dirs": "Dict from generator target_name -> result output directory",
    },
)

PrismaMigrationsInfo = provider(
    doc = "Information about a set of prisma migrations.",
    fields = {
        "migrations": "Depset containing the migration files",
        "schema_info": "PrismaSchemaInfo of the relevant schema",
    },
)
