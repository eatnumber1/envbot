DROP TABLE IF EXISTS savedmode;
CREATE TABLE savedmode (
	nick       TEXT        NOT NULL,
	ident      TEXT        NOT NULL,
	host       TEXT        NOT NULL,
	channel    TEXT        NOT NULL,
	operator   INTEGER     NOT NULL,
	voice      INTEGER     NOT NULL
);
