/*
 * This is how to create a factoid database
 * Use this file like this:
 * sqlite3 -batch data/envbot.db < doc/seen.sql
 *
 * If you use another table name, change below in
 * both places
 */
DROP TABLE IF EXISTS seen;
CREATE TABLE seen (
	nick       TEXT UNIQUE NOT NULL PRIMARY KEY,
	channel    TEXT        NOT NULL,
	timestamp  TEXT        NOT NULL,
	message    TEXT        NOT NULL
);
