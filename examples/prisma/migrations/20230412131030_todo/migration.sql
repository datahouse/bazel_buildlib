-- Create user roles.
-- Procedure to work around https://github.com/prisma/prisma/issues/6581
DO $$
BEGIN
  -- unpriviledged api role. this role is subject to row level security (RLS)
  IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'api') THEN
    RAISE NOTICE 'Role "api" already exists. Skipping.';
  ELSE
    CREATE ROLE api;
  END IF;

  -- priviledged api role.
  -- the api will log in with this role and downgrade to the api role
  -- for normal queries.
  -- it will use the priviledged role for api protected business logic.
  IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'api_priviledged') THEN
    RAISE NOTICE 'Role "api_priviledged" already exists. Skipping.';
  ELSE
    CREATE ROLE api_priviledged LOGIN NOINHERIT IN ROLE api BYPASSRLS;
  END IF;
END
$$;

-- allow both roles to access the public schema (at all).
GRANT USAGE ON SCHEMA public TO api_priviledged;
GRANT USAGE ON SCHEMA public TO api;

-- set default privileges for api_priviledged (same for every table)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO api_priviledged;

-- allow both roles to access sequences (needed for e.g. SERIAL)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO api_priviledged;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO api;

-- CreateTable
CREATE TABLE "User" (
    "id" SERIAL NOT NULL,
    "email" TEXT NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TodoList" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "ownerId" INTEGER NOT NULL,
    "archived" BOOLEAN NOT NULL,

    CONSTRAINT "TodoList_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TodoItem" (
    "id" SERIAL NOT NULL,
    "text" TEXT NOT NULL,
    "done" BOOLEAN NOT NULL,
    "listId" INTEGER NOT NULL,

    CONSTRAINT "TodoItem_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- AddForeignKey
ALTER TABLE "TodoList" ADD CONSTRAINT "TodoList_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TodoItem" ADD CONSTRAINT "TodoItem_listId_fkey" FOREIGN KEY ("listId") REFERENCES "TodoList"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Security
ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "TodoList" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "TodoItem" ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON "User" TO api;
GRANT SELECT, INSERT, UPDATE, DELETE ON "TodoList" TO api;
GRANT SELECT, INSERT, UPDATE, DELETE ON "TodoItem" TO api;

CREATE POLICY myself ON "User" TO api
  USING ("email" = current_setting('jwt.claims.sub'));

CREATE POLICY my_lists ON "TodoList" TO api
  USING ("ownerId" = (SELECT "id" FROM "User" WHERE "email" = current_setting('jwt.claims.sub')));

CREATE POLICY my_todos ON "TodoItem" TO api
  -- Queries inside USING also have RLS applied to them.
  -- So no need to repeat conditions.
  USING ("TodoItem"."listId" IN (SELECT "TodoList"."id" FROM "TodoList"))
