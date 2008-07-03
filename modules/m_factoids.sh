#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2008  Arvid Norlander                               #
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
## Simple factoids module using SQLite3
#---------------------------------------------------------------------

module_factoids_INIT() {
	modinit_API='2'
	modinit_HOOKS='after_load on_PRIVMSG'
	commands_register "$1" 'learn'                           || return 1
	commands_register "$1" 'forget'                          || return 1
	commands_register "$1" 'lock_factoid'   'lock factoid'   || return 1
	commands_register "$1" 'unlock_factoid' 'unlock factoid' || return 1
	commands_register "$1" 'whatis'                          || return 1
	commands_register "$1" 'factoid_stats'  'factoid stats'  || return 1
	helpentry_module_factoids_description="Provides a factoid database."

	helpentry_factoids_learn_syntax='<key> (as|is|are|=) <value>'
	helpentry_factoids_learn_description='Teach the bot a new factoid.'

	helpentry_factoids_forget_syntax='<key>'
	helpentry_factoids_forget_description='Make the bot forget the factoid <key>.'

	helpentry_factoids_lock_factoid_syntax='<key>'
	helpentry_factoids_lock_factoid_description='Prevent normal users from changing the factoid <key>.'

	helpentry_factoids_unlock_factoid_syntax='<key>'
	helpentry_factoids_unlock_factoid_description='Allow changes to a previously locked factoid <key>.'

	helpentry_factoids_whatis_syntax='<key>'
	helpentry_factoids_whatis_description='Look up the factoid <key>.'

	helpentry_factoids_factoid_stats_syntax=''
	helpentry_factoids_factoid_stats_description='Report some statistics on the factoid database.'
}


module_factoids_UNLOAD() {
	# Ok this is a LOT. I hope I got all...
	unset module_factoids_set module_factoids_remove module_factoids_parse_assignment
	unset module_factoids_parse_key module_factoids_parse_value
	unset module_factoids_set_INSERT_or_UPDATE module_factoids_send_factoid
	unset module_factoids_get_count module_factoids_get_locked_count
	unset module_factoids_is_locked module_factoids_lock module_factoids_unlock
	unset module_factoids_SELECT module_factoids_INSERT module_factoids_UPDATE module_factoids_DELETE
}


module_factoids_REHASH() {
	return 0
}


# Called after module has loaded.
module_factoids_after_load() {
	modules_depends_register "factoids" "sqlite3" || {
		# This error reporting is hackish, will fix later.
		if ! list_contains "modules_loaded" "sqlite3"; then
			log_error "The factoids module depends upon the SQLite3 module being loaded."
		fi
		return 1
	}
	if [[ -z $config_module_factoids_table ]]; then
		log_error "Factiods table (config_module_factoids_table) must be set in config if you want to use factoids module."
		return 1
	fi
	if ! module_sqlite3_table_exists "$config_module_factoids_table"; then
		log_error "factoids module: $config_module_factoids_table does not exist in the database file."
		log_error "factoids module: See comment in doc/factoids.sql for how to create the table."
	fi
}


#---------------------------------------------------------------------
## Get an item from DB
## @Type Private
## @param Key
## @Stdout The result of the database query.
#---------------------------------------------------------------------
module_factoids_SELECT() {
	#$ sqlite3 -list data/factoids.sqlite "SELECT value from factoids WHERE name='factoids';"
	#A system that stores useful bits of information
	module_sqlite3_exec_sql "SELECT value FROM $config_module_factoids_table WHERE name='$(module_sqlite3_clean_string "$1")';"
}


#---------------------------------------------------------------------
## Insert a new item into DB
## @Type Private
## @param key
## @param value
## @param hostmask of person who added it
#---------------------------------------------------------------------
module_factoids_INSERT() {
	module_sqlite3_exec_sql \
		"INSERT INTO $config_module_factoids_table (name, value, who) VALUES('$(module_sqlite3_clean_string "$1")', '$(module_sqlite3_clean_string "$2")', '$(module_sqlite3_clean_string "$3")');"
}


#---------------------------------------------------------------------
## Change the item in DB
## @Type Private
## @param key
## @param new value
## @param hostmask of person who changed it
#---------------------------------------------------------------------
module_factoids_UPDATE() {
	module_sqlite3_exec_sql \
		"UPDATE $config_module_factoids_table SET value='$(module_sqlite3_clean_string "$2")', who='$(module_sqlite3_clean_string "$3")' WHERE name='$(module_sqlite3_clean_string "$1")';"
}


#---------------------------------------------------------------------
## Remove an item
## @Type Private
## @param key
#---------------------------------------------------------------------
module_factoids_DELETE() {
	module_sqlite3_exec_sql "DELETE FROM $config_module_factoids_table WHERE name='$(module_sqlite3_clean_string "$1")';"
}


#---------------------------------------------------------------------
## How many factoids are there
## @Type Private
## @Stdout Count of factoids.
#---------------------------------------------------------------------
module_factoids_get_count() {
	module_sqlite3_exec_sql "SELECT COUNT(name) FROM $config_module_factoids_table;"
}


#---------------------------------------------------------------------
## How many locked factoids are there
## @Type Private
## @Stdout Count of locked factoids.
#---------------------------------------------------------------------
module_factoids_get_locked_count() {
	module_sqlite3_exec_sql "SELECT COUNT(name) FROM $config_module_factoids_table WHERE is_locked='1';"
}


#---------------------------------------------------------------------
## Check if factoid is locked or not.
## @Type Private
## @param key
## @return 0 locked
## @return 1 not locked
#---------------------------------------------------------------------
module_factoids_is_locked() {
	local lock="$(module_sqlite3_exec_sql "SELECT is_locked FROM $config_module_factoids_table WHERE name='$(module_sqlite3_clean_string "$1")';")"
	if [[ $lock == "1" ]]; then
		return 0
	else
		return 1
	fi
}


#---------------------------------------------------------------------
## Lock a factoid against changes from non-owners
## @Type Private
## @param key
#---------------------------------------------------------------------
module_factoids_lock() {
	module_sqlite3_exec_sql "UPDATE $config_module_factoids_table SET is_locked='1' WHERE name='$(module_sqlite3_clean_string "$1")';"
}


#---------------------------------------------------------------------
## Unlock a factoid from protection against non-owners
## @Type Private
## @param key
#---------------------------------------------------------------------
module_factoids_unlock() {
	module_sqlite3_exec_sql "UPDATE $config_module_factoids_table SET is_locked='0' WHERE name='$(module_sqlite3_clean_string "$1")';"
}


#---------------------------------------------------------------------
## Wrapper, call either INSERT or UPDATE
## @Type Private
## @param key
## @param value
## @param hostmask of person set it
#---------------------------------------------------------------------
module_factoids_set_INSERT_or_UPDATE() {
	if [[ $(module_factoids_SELECT "$1") ]]; then
		module_factoids_UPDATE "$1" "$2" "$3"
	else
		module_factoids_INSERT "$1" "$2" "$3"
	fi
}


#---------------------------------------------------------------------
## Wrapper, call either INSERT or UPDATE
## @Type Private
## @param key
## @param value
## @param sender
## @param channel
#---------------------------------------------------------------------
module_factoids_set() {
	local key="$1"
	local value="$2"
	local sender="$3"
	local channel="$4"
	local sendernick
	parse_hostmask_nick "$sender" 'sendernick'
	if module_factoids_is_locked "$key"; then
		if access_check_capab "factoid_admin" "$sender" "GLOBAL"; then
			module_factoids_set_INSERT_or_UPDATE "$key" "$value" "$sender"
			send_msg "$channel" "Ok ${sendernick}, I will remember, $key is $value"
		else
			access_fail "$sender" "change a locked factoid" "factoid_admin"
		fi
	else
		module_factoids_set_INSERT_or_UPDATE "$key" "$value" "$sender"
		send_msg "$channel" "Ok ${sendernick}, I will remember, $key is $value"
	fi
}


#---------------------------------------------------------------------
## Wrapper, check access
## @Type Private
## @param key
## @param sender
## @param channel
#---------------------------------------------------------------------
module_factoids_remove() {
	local key="$1"
	local sender="$2"
	local channel="$3"
	local value="$(module_factoids_SELECT "$(tr '[:upper:]' '[:lower:]' <<< "$key")")"
	if [[ "$value" ]]; then
		if module_factoids_is_locked "$key"; then
			if access_check_capab "factoid_admin" "$sender" "GLOBAL"; then
				module_factoids_DELETE "$key"
				send_msg "$channel" "I forgot $key"
			else
				access_fail "$sender" "remove a locked factoid" "factoid_admin"
			fi
		else
			module_factoids_DELETE "$key"
			send_msg "$channel" "I forgot $key"
		fi
	else
		send_msg "$channel" "I didn't have a factoid matching \"$key\""
	fi
}


#---------------------------------------------------------------------
## Send the factoid:
## @Type Private
## @param To where (channel or nick)
## @param What factoid.
#---------------------------------------------------------------------
module_factoids_send_factoid() {
	local channel="$1"
	local key="$2"
	local value="$(module_factoids_SELECT "$(tr '[:upper:]' '[:lower:]' <<< "$key")")"
	if [[ "$value" ]]; then
		if [[ $value =~ ^\<REPLY\>\ *(.*) ]]; then
			send_msg "$channel" "${BASH_REMATCH[1]}"
		elif [[ $value =~ ^\<ACTION\>\ *(.*) ]]; then
			send_ctcp "$channel" "ACTION ${BASH_REMATCH[1]}"
		else
			send_msg "$channel" "$key is $value"
		fi
	else
		send_msg "$channel" "I don't know what \"$key\" is."
	fi
}


#---------------------------------------------------------------------
## Parse assignment:
## @Type Private
## @param String to parse
## @Note Will return using Global variables
## @Globals $module_factoids_parse_key $module_factoids_parse_value
#---------------------------------------------------------------------
module_factoids_parse_assignment() {
	local word key value
	# Have we hit a separator yet?
	local state=0
	while read -rd ' ' word; do
		case "$state" in
			0)
				# If state is 1 the rest is value
				if [[ "$word" =~ ^(as|is|are|=)$ ]]; then
					state=1
				else
					key+=" $word"
				fi
				;;
			1)
				value+=" $word"
				;;
		esac
	# Extra space at end is intended, to make read work correctly.
	done <<< "$1 "
	# And clean spaces, fastest way
	read -ra module_factoids_parse_key <<< "$key"
	read -ra module_factoids_parse_value <<< "$value"
}


module_factoids_handler_learn() {
	local sender="$1"
	local sendernick
	parse_hostmask_nick "$sender" 'sendernick'
	local channel="$2"
	if ! [[ $2 =~ ^# ]]; then
		channel="$sendernick"
	fi
	local parameters="$3"
	if [[ "$parameters" =~ ^(.+)\ (as|is|are|=)\ (.+) ]]; then
		# Do the actual parsing elsewhere:
		module_factoids_parse_assignment "$parameters"
		local key="${module_factoids_parse_key[*]}"
		local value="${module_factoids_parse_value[*]}"
		unset module_factoids_parse_key module_factoids_parse_value
		module_factoids_set "$(tr '[:upper:]' '[:lower:]' <<< "$key")" "$value" "$sender" "$channel"
	else
		feedback_bad_syntax "$sendernick" "learn" "<key> (as|is|are|=) <value>"
	fi
	return 1
}

module_factoids_handler_forget() {
	local sender="$1"
	local sendernick
	parse_hostmask_nick "$sender" 'sendernick'
	local channel="$2"
	if ! [[ $2 =~ ^# ]]; then
		channel="$sendernick"
	fi
	local parameters="$3"
	if [[ "$parameters" =~ ^(.+) ]]; then
		local key="${BASH_REMATCH[1]}"
		module_factoids_remove "$(tr '[:upper:]' '[:lower:]' <<< "$key")" "$sender" "$channel"
	else
		feedback_bad_syntax "$sendernick" "forget" "<key>"
	fi
}

module_factoids_handler_lock_factoid() {
	local sender="$1"
	if access_check_capab "factoid_admin" "$sender" "GLOBAL"; then
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		local channel="$2"
		if ! [[ $2 =~ ^# ]]; then
			channel="$sendernick"
		fi
		local parameters="$3"
		if [[ "$parameters" =~ ^(.+) ]]; then
			local key="${BASH_REMATCH[1]}"
			module_factoids_lock "$(tr '[:upper:]' '[:lower:]' <<< "$key")"
			send_msg "$channel" "Ok ${sendernick}, the factoid \"$key\" is now protected from changes"
		else
			feedback_bad_syntax "$sendernick" "lock" "<key>"
		fi
	else
		access_fail "$sender" "lock a factoid" "factoid_admin"
	fi
}

module_factoids_handler_unlock_factoid() {
	local sender="$1"
	if access_check_capab "factoid_admin" "$sender" "GLOBAL"; then
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		local channel="$2"
		if ! [[ $2 =~ ^# ]]; then
			channel="$sendernick"
		fi
		local parameters="$3"
		if [[ "$parameters" =~ ^(.+) ]]; then
			local key="${BASH_REMATCH[1]}"
			module_factoids_unlock "$(tr '[:upper:]' '[:lower:]' <<< "$key")"
			send_msg "$channel" "Ok ${sendernick}, the factoid \"$key\" is no longer protected from changes"
		else
			feedback_bad_syntax "$sendernick" "lock" "<key>"
		fi
	else
		access_fail "$sender" "lock a factoid" "factoid_admin"
	fi
}

module_factoids_handler_whatis() {
	local sender="$1"
	local sendernick
	parse_hostmask_nick "$sender" 'sendernick'
	local channel="$2"
	if ! [[ $2 =~ ^# ]]; then
		channel="$sendernick"
	fi
	local parameters="$3"
	if [[ "$parameters" =~ ^(.+) ]]; then
		local key="${BASH_REMATCH[1]}"
		module_factoids_send_factoid "$channel" "$key"
	else
		feedback_bad_syntax "$sendernick" "whatis" "<key>"
	fi
}

module_factoids_handler_factoid_stats() {
	local sender="$1"
	local channel="$2"
	if ! [[ $2 =~ ^# ]]; then
		parse_hostmask_nick "$sender" 'channel'
	fi
	local count="$(module_factoids_get_count)"
	local lockedcount="$(module_factoids_get_locked_count)"
	if [[ "$count" ]]; then
		send_msg "$channel" "There are $count items in my factoid database. $lockedcount of the factoids are locked."
	fi
}

module_factoids_on_PRIVMSG() {
	local sender="$1"
	local channel="$2"
	if ! [[ $2 =~ ^# ]]; then
		parse_hostmask_nick "$sender" 'channel'
	fi
	local query="$3"
	# Answer question in channel if we got a factoid.
	if [[ "$query" =~ ^((what|where|who|why|how)\ )?((is|are|were|was|to|can I find)\ )?([^\?]+)\?? ]]; then
		local key="${BASH_REMATCH[@]: -1}"
		local value="$(module_factoids_SELECT "$(tr '[:upper:]' '[:lower:]' <<< "$key")")"
		if [[ "$value" ]]; then
			module_factoids_send_factoid "$channel" "$key"
			return 1
		fi
	fi
	return 0
}
