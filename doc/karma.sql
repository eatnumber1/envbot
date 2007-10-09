/*
 * This is how to create a factoid database
 * Use this file like this:
 * sqlite3 -batch data/envbot.db < doc/karma.sql
 *
 * If you use another table name, change below in
 * both places
 */
DROP TABLE IF EXISTS karma;
CREATE TABLE karma (
	target     TEXT    UNIQUE NOT NULL PRIMARY KEY,
	rating     INTEGER        NOT NULL,
	is_locked  INTEGER        NOT NULL
);
