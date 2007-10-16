#!/bin/bash
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
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
#---------------------------------------------------------------------
## Karma module
#---------------------------------------------------------------------

module_karma_INIT() {
	echo 'after_load on_PRIVMSG'
}

module_karma_UNLOAD() {
	unset module_karma_SELECT
	unset module_karma_INSERT module_karma_UPDATE module_karma_set_INSERT_or_UPDATE
	unset module_karma_substract module_karma_add module_karma_check
	unset module_karma_is_nick
	return 0
}

module_karma_REHASH() {
	return 0
}

module_karma_after_load() {
	modules_depends_register "karma" "sqlite3" || {
		# This error reporting is hackish, will fix later.
		if ! list_contains "modules_loaded" "sqlite3"; then
			log_error "The karma module depends upon the SQLite3 module being loaded."
		fi
		return 1
	}
	if [[ -z $config_module_karma_table ]]; then
		log_error "Karma table (config_module_karma_table) must be set in config to use the karma module."
		return 1
	fi
	if ! module_sqlite3_table_exists "$config_module_karma_table"; then
		log_error "karma module: $config_module_karma_table does not exist in the database file."
		log_error "karma module: See comment in doc/karma.sql for how to create the table."
	fi
}

#---------------------------------------------------------------------
## Get an item from DB
## @Type Private
## @param key
## @Stdout The result of the database query.
#---------------------------------------------------------------------
module_karma_SELECT() {
	module_sqlite3_exec_sql "SELECT rating FROM $config_module_karma_table WHERE target='$(module_sqlite3_clean_string "$1")';"
}


#---------------------------------------------------------------------
## Insert a new item into DB
## @Type Private
## @param key
## @param karma
#---------------------------------------------------------------------
module_karma_INSERT() {
	module_sqlite3_exec_sql \
		"INSERT INTO $config_module_karma_table (target, rating) VALUES('$(module_sqlite3_clean_string "$1")', '$(module_sqlite3_clean_string "$2")');"
}


#---------------------------------------------------------------------
## Change the item in DB
## @Type Private
## @param key
## @param karma
#---------------------------------------------------------------------
module_karma_UPDATE() {
	module_sqlite3_exec_sql \
		"UPDATE $config_module_karma_table SET rating='$(module_sqlite3_clean_string "$2")' WHERE target='$(module_sqlite3_clean_string "$1")';"
}

#---------------------------------------------------------------------
## Wrapper, call either INSERT or UPDATE
## @Type Private
## @param key
## @param karma
#---------------------------------------------------------------------
module_karma_set_INSERT_or_UPDATE() {
	if [[ $(module_karma_SELECT "$1") ]]; then
		module_karma_UPDATE "$1" "$2"
	else
		module_karma_INSERT "$1" "$2"
	fi
}

#---------------------------------------------------------------------
## Remove 1 from key
## @Type Private
## @param key to remove from.
#---------------------------------------------------------------------
module_karma_substract() {
	# Clean spaces and convert to lower case
	local keyarray
	read -ra keyarray <<< "$1"
	local key="$(tr '[:upper:]' '[:lower:]' <<< "${keyarray[*]}")"
	local old="$(module_karma_SELECT "$key")"
	# -1 + any old value (yes looks backwards but works)
	local new=-1
	if [[ "$old" ]]; then
		(( new += old ))
	fi
	module_karma_set_INSERT_or_UPDATE "$key" "$new"
}

#---------------------------------------------------------------------
## Add 1 from key
## @Type Private
## @param key to add to.
#---------------------------------------------------------------------
module_karma_add() {
	# Clean spaces and convert to lower case
	local keyarray
	read -ra keyarray <<< "$1"
	local key="$(tr '[:upper:]' '[:lower:]' <<< "${keyarray[*]}")"
	local old="$(module_karma_SELECT "$key")"
	# 1 + any old value
	local new=1
	if [[ "$old" ]]; then
		(( new += old ))
	fi
	module_karma_set_INSERT_or_UPDATE "$key" "$new"
}

#---------------------------------------------------------------------
## Return karma value for key
## @Type Private
## @param key to return karma for (on STDOUT)
#---------------------------------------------------------------------
module_karma_check() {
	# Clean spaces and convert to lower case
	local keyarray
	read -ra keyarray <<< "$1"
	local key="$(tr '[:upper:]' '[:lower:]' <<< "${keyarray[*]}")"
	local value="$(module_karma_SELECT "$key")"
	if [[ -z "$value" ]]; then
		value=0
	fi
	echo "$value"
}

#---------------------------------------------------------------------
## Check if the key is the nick of sender.
## @Type Private
## @param key
## @param sender
## @return 0 If nick and key are same
## @return 1 Otherwise
#---------------------------------------------------------------------
module_karma_is_nick() {
	local keyarray
	read -ra keyarray <<< "$1"
	local key="$(tr '[:upper:]' '[:lower:]' <<< "${keyarray[*]}")"
	local nickarray
	read -ra nickarray <<< "$(parse_hostmask_nick_stdout "$2" | tr '[:upper:]' '[:lower:]')"
	local nick="${nickarray[*]}"
	if [[ "$key" = "$nick" ]]; then
		return 0
	fi
	return 1
}


# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_karma_on_PRIVMSG() {
	local sender="$1"
	local query="$3"
	local sendon_channel
	# If it isn't in a channel send message back to person who sent it,
	# otherwise send in channel
	if [[ $2 =~ ^# ]]; then
		sendon_channel="$2"
		# An item must begin with an alphanumeric char.
		if [[ "$query" =~ ^([a-zA-Z0-9].*)\+\+$ ]]; then
			local key="${BASH_REMATCH[1]}"
			if module_karma_is_nick "$key" "$sender"; then
				send_msg "$sendon_channel" "You can't change karma of yourself."
			else
				module_karma_add "$key"
			fi
		elif [[ "$query" =~ ^([a-zA-Z0-9].*)--$ ]]; then
			local key="${BASH_REMATCH[1]}"
			if module_karma_is_nick "$key" "$sender"; then
				send_msg "$sendon_channel" "You can't change karma of yourself."
			else
				module_karma_substract "$key"
			fi
		fi
	else
		parse_hostmask_nick "$sender" 'sendon_channel'
		# Karma is only possible in channels
		if [[ "$query" =~ ^[a-zA-Z0-9].*(--|\+\+)$ ]]; then
			send_msg "$sendon_channel" "You can only change karma in channels."
			return 1
		fi
	fi

	if parameters="$(parse_query_is_command "$query" "karma")"; then
		if [[ $parameters =~ ^(.+)$ ]]; then
			local key="${BASH_REMATCH[1]}"
			local value="$(module_karma_check "$key")"
			send_msg "$sendon_channel" "Karma for $key is $value"
		else
			local sendernick
			parse_hostmask_nick "$sender" 'sendernick'
			feedback_bad_syntax "$sendernick" "karma" "item"
		fi
		return 1
	fi
	return 0
}
