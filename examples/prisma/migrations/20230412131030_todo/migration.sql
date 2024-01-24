-- Create user roles.
-- Procedure to work around https://github.com/prisma/prisma/issues/6581
DO $$
BEGIN
  -- unpriviledged api role. this role is used for operations directly exposed to the API.
  -- it is subject to RLS and only allowed to do things users may alter directly.
  IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'api') THEN
    RAISE NOTICE 'Role "api" already exists. Skipping.';
  ELSE
    CREATE ROLE api;
  END IF;

  -- elevated api role. used by the API when we do API protected transactions.
  -- it can do everything the API role can but additional things that need api
  -- protection (e.g. file uploads or state transitions)
  IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'api_elevated') THEN
    RAISE NOTICE 'Role "api_elevated" already exists. Skipping.';
  ELSE
    CREATE ROLE api_elevated INHERIT IN ROLE api;
  END IF;

  -- api login role.
  -- the api will log in with this role and switch to the appropriate other role.
  -- this role deliberately does not have any privileges on its own.
  -- this avoids accidental ambient privilege if switching to another role is forgotten.
  IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'api_login') THEN
    RAISE NOTICE 'Role "api_login" already exists. Skipping.';
  ELSE
    CREATE ROLE api_login LOGIN NOINHERIT IN ROLE api, api_elevated;
  END IF;
END
$$;

-- allow access to the public schema (at all).
GRANT USAGE ON SCHEMA public TO api;

-- allow access to sequences (needed for e.g. SERIAL)
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

-- CreateTable
CREATE TABLE "TodoAttachment" (
    "id" SERIAL NOT NULL,
    "itemId" INTEGER NOT NULL,
    "filename" TEXT NOT NULL,
    "mimetype" TEXT NOT NULL,
    "uuid" UUID NOT NULL,

    CONSTRAINT "TodoAttachment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
CREATE UNIQUE INDEX "TodoAttachment_uuid_key" ON "TodoAttachment"("uuid");

-- AddForeignKey
ALTER TABLE "TodoList" ADD CONSTRAINT "TodoList_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TodoItem" ADD CONSTRAINT "TodoItem_listId_fkey" FOREIGN KEY ("listId") REFERENCES "TodoList"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TodoAttachment" ADD CONSTRAINT "TodoAttachment_itemId_fkey" FOREIGN KEY ("itemId") REFERENCES "TodoItem"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Security
ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "TodoList" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "TodoItem" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "TodoAttachment" ENABLE ROW LEVEL SECURITY;

-- Coarse grained permissions

GRANT SELECT ON "User" TO api;
GRANT SELECT, INSERT, UPDATE, DELETE ON "TodoList" TO api;
GRANT SELECT, INSERT, UPDATE, DELETE ON "TodoItem" TO api;

-- Attachments can only be deleted and re-added. No modifications.
-- Only api elevated operations can modify attachments:
-- They need to keep it in sync with the blob store.

GRANT SELECT ON "TodoAttachment" TO api;
GRANT INSERT, DELETE ON "TodoAttachment" TO api_elevated;

-- Fine grained permissions

CREATE POLICY myself ON "User" TO api
  USING ("email" = current_setting('jwt.claims.sub'));

CREATE POLICY my_lists ON "TodoList" TO api
  USING ("ownerId" = (SELECT "id" FROM "User" WHERE "email" = current_setting('jwt.claims.sub')));

CREATE POLICY my_todos ON "TodoItem" TO api
  -- Queries inside USING also have RLS applied to them.
  -- So no need to repeat conditions.
  USING ("TodoItem"."listId" IN (SELECT "TodoList"."id" FROM "TodoList"));

CREATE POLICY read_my_attachments ON "TodoAttachment" FOR SELECT TO api
  USING ("TodoAttachment"."itemId" IN (SELECT "TodoItem"."id" FROM "TodoItem"));

CREATE POLICY add_my_attachments ON "TodoAttachment" FOR INSERT TO api_elevated
  WITH CHECK ("TodoAttachment"."itemId" IN (SELECT "TodoItem"."id" FROM "TodoItem"));

CREATE POLICY delete_my_attachments ON "TodoAttachment" FOR DELETE TO api_elevated
  USING ("TodoAttachment"."itemId" IN (SELECT "TodoItem"."id" FROM "TodoItem"));
