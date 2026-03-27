DO
$do$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'movies_user') THEN
      CREATE ROLE movies_user LOGIN PASSWORD '123456';
   END IF;
END
$do$;

SELECT 'CREATE DATABASE movies_db OWNER movies_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'movies_db')\gexec

\c movies_db
GRANT ALL ON SCHEMA public TO movies_user;
ALTER SCHEMA public OWNER TO movies_user;