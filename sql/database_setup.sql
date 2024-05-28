\c postgres;

CREATE DATABASE prjdb;

CREATE USER prjadmin WITH PASSWORD 'prjadmin';

\c prjdb;

GRANT ALL ON SCHEMA PUBLIC TO prjadmin;

