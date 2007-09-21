/*
 * This is how to create a factoid database
 * Use this file like this:
 * sqlite3 -batch data/envbot.db < doc/factoids.sql
 *
 * If you use another table name, change below in
 * both places
 */
DROP TABLE IF EXISTS factoids;
CREATE TABLE factoids (
	name       TEXT UNIQUE NOT NULL PRIMARY KEY,
	value      TEXT        NOT NULL,
	who        TEXT        NOT NULL,
	is_locked  INTEGER     NOT NULL DEFAULT 0
);
