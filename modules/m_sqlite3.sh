#!/bin/bash
###########################################################################
#                                                                         #
#  envbot - an irc bot in bash                                            #
#  Copyright (C) 2007  Arvid Norlander                                    #
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
# This module allows other modules to access a SQLite3 database in a
# "simple" way.
###########################################
# WARNING WARNING WARNING WARNING WARNING #
#                                         #
#    USE UTF8 when editing this file!!    #
#      Otherwise the file WILL break      #
#                                         #
# WARNING WARNING WARNING WARNING WARNING #
###########################################
module_sqlite3_INIT() {
	echo 'after_load'
}

module_sqlite3_UNLOAD() {
	unset module_sqlite3_after_load
	unset module_sqlite3_clean_string module_sqlite3_exec_sql
}

module_faq_REHASH() {
	return 0
}

# Called after module has loaded.
# Loads FAQ items
module_sqlite3_after_load() {
	# Check (silently) for sqlite3
	type -p sqlite3 &> /dev/null
	if [[ $? -ne 0 ]]; then
		log_stdout "Couldn't find sqlite3 command line tool. The sqlite3 module depend on that tool."
		return 1
	fi
	if ! [[ -r $config_module_sqlite3_database ]]; then
		log_stdout "Seen database file doesn't exist or can't be read!"
		log_stdout "See comment in doc/seen.sql for how to create one."
		return 1
	fi
}

# Make string safe for SQL.
# Parameters:
#   $1 String to clean
# Yes we just discard double quotes atm.
module_sqlite3_clean_string() {
	# \055 = -, yes hackish workaround.
	tr -Cd 'A-Za-z0-9\055 ,;.:_<>*|~^!"#%&/()=?+\@${}[]+ÅÄÖåäö'\' <<< "$1" | sed "s/'/''/g"
}

# Parameters:
#   $1 Query to run
module_sqlite3_exec_sql() {
	sqlite3 -list "$config_module_sqlite3_database" "$1"
}
