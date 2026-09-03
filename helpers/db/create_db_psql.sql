SELECT NOT EXISTS (
    SELECT 1
    FROM pg_roles
    WHERE rolname = :'user_name'
) AS role_missing
\gset

\if :role_missing
CREATE ROLE :"user_name"
    WITH LOGIN ENCRYPTED PASSWORD :'user_password';
\endif

ALTER ROLE :"user_name"
    WITH LOGIN ENCRYPTED PASSWORD :'user_password';

SELECT NOT EXISTS (
    SELECT 1
    FROM pg_database
    WHERE datname = :'database_name'
) AS database_missing
\gset

\if :database_missing
CREATE DATABASE :"database_name"
    WITH OWNER :"user_name";
\endif

ALTER DATABASE :"database_name"
    OWNER TO :"user_name";
