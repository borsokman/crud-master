DO
$do$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'orders_user') THEN
      CREATE ROLE orders_user LOGIN PASSWORD '654321';
   END IF;
END
$do$;

SELECT 'CREATE DATABASE billing_db OWNER orders_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'billing_db')\gexec

\c billing_db
GRANT ALL ON SCHEMA public TO orders_user;
ALTER SCHEMA public OWNER TO orders_user;