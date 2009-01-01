#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2009  Arvid Norlander                               #
#                                                                         #
#  This program is free software: you can redistribute it and/or modify   #
#  it under the terms of the GNU General Public License as published by   #
#  the Free Software Foundation, either version 3 of the License, or      #
#  (at your option) any later version.                                    #
#                                                                         #
#  This program is distributed in the hope that it will be useful,        #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of         #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
#  GNU General Public License for more details.                           #
#                                                                         #
#  You should have received a copy of the GNU General Public License      #
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.  #
#                                                                         #
###########################################################################
#---------------------------------------------------------------------
## This module allows other modules to access a SQLite3 database in a
## "simple" way.
#---------------------------------------------------------------------

module_sqlite3_INIT() {
	modinit_API='2'
	modinit_HOOKS='after_load'
	helpentry_module_sqlite3_description="Provides sqlite3 database backend for other modules."
}

module_sqlite3_UNLOAD() {
	unset module_sqlite3_clean_string module_sqlite3_exec_sql module_sqlite3_table_exists
}

module_sqlite3_REHASH() {
	return 0
}

# Called after module has loaded.
module_sqlite3_after_load() {
	# Check (silently) for sqlite3
	if ! hash sqlite3 > /dev/null 2>&1; then
		log_error "Couldn't find sqlite3 command line tool. The sqlite3 module depends on that tool."
		return 1
	fi
	if [[ -z $config_module_sqlite3_database ]]; then
		log_error "You must set config_module_sqlite3_database in your config to use the sqlite3 module."
		return 1
	fi
	if ! [[ -r $config_module_sqlite3_database ]]; then
		log_error "sqlite3 module: Database file doesn't exist or can't be read!"
		log_error "sqlite3 module: To create one follow the comments in one (or several) of the sql files in the doc directory."
		return 1
	fi
}

#---------------------------------------------------------------------
## Make string safe for SQLite3.
## @Type API
## @param String to clean
## @Note IMPORTANT FOR SECURITY!: Only use the result inside single
## @Note quotes ('), NEVER inside double quotes (").
## @Note The output isn't safe for that.
#---------------------------------------------------------------------
module_sqlite3_clean_string() {
	sed "s/'/''/g" <<< "$1"
}

#---------------------------------------------------------------------
## Run the query against the data base.
## @Type API
## @param Query to run
#---------------------------------------------------------------------
module_sqlite3_exec_sql() {
	sqlite3 -list "$config_module_sqlite3_database" "$1"
}

#---------------------------------------------------------------------
## Check if a table exists in the database file.
## @Type API
## @param The table name to check for
## @return 0 If table exists
## @return 1 If table doesn't exist.
#---------------------------------------------------------------------
module_sqlite3_table_exists() {
	sqlite3 -list "$config_module_sqlite3_database" ".tables" | grep -qw "$1"
}
