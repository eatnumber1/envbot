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
# Simple factoids module using sqlite3

module_factoids_INIT() {
	echo 'after_load on_PRIVMSG'
}

module_factoids_UNLOAD() {
	# Ok this is a LOT. I hope I got all...
	unset module_factoids_set module_factoids_remove
	unset module_factoids_set_INSERT_or_UPDATE module_factoids_send_factoid
	unset module_factoids_get_count module_factoids_get_locked_count
	unset module_factoids_is_locked module_factoids_lock module_factoids_unlock
	unset module_factoids_SELECT module_factoids_INSERT module_factoids_UPDATE module_factoids_DELETE
}

module_factoids_REHASH() {
	return 0
}


# Called after module has loaded.
# Loads FAQ items
module_factoids_after_load() {
	# HACK: I should add proper dependency checking. This will break on unloading sqlite3 module
	if ! list_contains "modules_loaded" "sqlite3"; then
		log_stdout "The factoids module depends upon the SQLite3 module being loaded before it"
		return 1
	fi
	if [[ -z $config_module_factoids_table ]]; then
		log_stdout "Factiods table (config_module_factoids_table) must be set in config."
		return 1
	fi
}

# Get an item from DB
# $1 = key
module_factoids_SELECT() {
	#$ sqlite3 -list data/factoids.sqlite "SELECT value from factoids WHERE name='factoids';"
	#A system that stores useful bits of information
	module_sqlite3_exec_sql "SELECT value FROM $config_module_factoids_table WHERE name='$(module_sqlite3_clean_string "$1")';"
}

# Insert a new item into DB
# $1 = key
# $2 = value
# $3 = hostmask of person who added it
module_factoids_INSERT() {
	module_sqlite3_exec_sql \
		"INSERT INTO $config_module_factoids_table (name, value, who) VALUES('$(module_sqlite3_clean_string "$1")', '$(module_sqlite3_clean_string "$2")', '$(module_sqlite3_clean_string "$3")');"
}

# Change the item in DB
# $1 = key
# $2 = new value
# $3 = hostmask of person who changed it
module_factoids_UPDATE() {
	module_sqlite3_exec_sql \
		"UPDATE $config_module_factoids_table SET value='$(module_sqlite3_clean_string "$2")', who='$(module_sqlite3_clean_string "$3")' WHERE name='$(module_sqlite3_clean_string "$1")';"
}

# Remove an item
# $1 = key
module_factoids_DELETE() {
	module_sqlite3_exec_sql "DELETE FROM $config_module_factoids_table WHERE name='$(module_sqlite3_clean_string "$1")';"
}

# How many factoids are there
module_factoids_get_count() {
	module_sqlite3_exec_sql "SELECT COUNT(name) FROM $config_module_factoids_table;"
}
# How many locked factoids are there
module_factoids_get_locked_count() {
	module_sqlite3_exec_sql "SELECT COUNT(name) FROM $config_module_factoids_table WHERE is_locked='1';"
}
# Check if factoid is locked or not.
# $1 = key
# Return 0 = locked
#        1 = not locked
module_factoids_is_locked() {
	local lock="$(module_sqlite3_exec_sql "SELECT is_locked FROM $config_module_factoids_table WHERE name='$(module_sqlite3_clean_string "$1")';")"
	if [[ $lock == "1" ]]; then
		return 0
	else
		return 1
	fi
}

# Lock a factoid against changes from non-owners
# $1 = key
module_factoids_lock() {
	module_sqlite3_exec_sql "UPDATE $config_module_factoids_table SET is_locked='1' WHERE name='$(module_sqlite3_clean_string "$1")';"
}

# Unlock a factoid from protection against non-owners
# $1 = key
module_factoids_unlock() {
	module_sqlite3_exec_sql "UPDATE $config_module_factoids_table SET is_locked='0' WHERE name='$(module_sqlite3_clean_string "$1")';"
}

# Wrapper, call either INSERT or UPDATE
# $1 = key
# $2 = value
# $3 = hostmask of person set it
module_factoids_set_INSERT_or_UPDATE() {
	if [[ $(module_factoids_SELECT "$1") ]]; then
		module_factoids_UPDATE "$1" "$2" "$3"
	else
		module_factoids_INSERT "$1" "$2" "$3"
	fi
}

# Wrapper, call either INSERT or UPDATE
# $1 = key
# $2 = value
# $3 = sender
# $4 = channel
module_factoids_set() {
	local key="$1"
	local value="$2"
	local sender="$3"
	local channel="$4"
	if module_factoids_is_locked "$key"; then
		if access_check_capab "factoid_admin" "$sender" "GLOBAL"; then
			module_factoids_set_INSERT_or_UPDATE "$key" "$value" "$sender"
			send_msg "$channel" "Ok $(parse_hostmask_nick "$sender"), I will remember, $key is $value"
		else
			access_fail "$sender" "change a locked faq item" "factoid_admin"
		fi
	else
		module_factoids_set_INSERT_or_UPDATE "$key" "$value" "$sender"
		send_msg "$channel" "Ok $(parse_hostmask_nick "$sender"), I will remember, $key is $value"
	fi
}

# Wrapper, check access
# $1 = key
# $2 = sender
# $3 = channel
module_factoids_remove() {
	if module_factoids_is_locked "$1"; then
		if access_check_capab "factoid_admin" "$2" "GLOBAL"; then
			module_factoids_DELETE "$1"
			send_msg "$channel" "I forgot $key"
		else
			access_fail "$sender" "remove a locked faq item" "factoid_admin"
		fi
	else
		module_factoids_DELETE "$1"
		send_msg "$channel" "I forgot $key"
	fi
}

# Send the factoid:
# $1 To where (channel or nick)
# $2 What factoid.
module_factoids_send_factoid() {
	local channel="$1"
	local key="$2"
	local value="$(module_factoids_SELECT "$(tr '[:upper:]' '[:lower:]' <<< "$key")")"
	if [[ "$value" ]]; then
		if [[ $value =~ ^\<REPLY\>(.*) ]]; then
			send_msg "$channel" "${BASH_REMATCH[1]}"
		elif [[ $value =~ ^\<ACTION\>(.*) ]]; then
			send_ctcp "$channel" "ACTION ${BASH_REMATCH[1]}"
		else
			send_msg "$channel" "$key is $value"
		fi
	else
		send_msg "$channel" "I don't know what \"$key\" is."
	fi
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_factoids_on_PRIVMSG() {
	# Only respond in channel.
	local sender="$1"
	local channel="$2"
	if ! [[ $2 =~ ^# ]]; then
		channel="$(parse_hostmask_nick "$sender")"
	fi
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "learn")"; then
		if [[ "$parameters" =~ ^(.+)\ (as|is|=)\ (.*) ]]; then
			local key="${BASH_REMATCH[1]}"
			local value="${BASH_REMATCH[3]}"
			module_factoids_set "$(tr '[:upper:]' '[:lower:]' <<< "$key")" "$value" "$sender" "$channel"
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "learn" "key (as|is|was|=) value"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "forget")"; then
		if [[ "$parameters" =~ ^(.+) ]]; then
			local key="${BASH_REMATCH[1]}"
			module_factoids_remove "$(tr '[:upper:]' '[:lower:]' <<< "$key")" "$sender" "$channel"
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "forget" "key"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "lock factoid")"; then
		if access_check_capab "factoid_admin" "$sender" "GLOBAL"; then
			if [[ "$parameters" =~ ^(.+) ]]; then
				local key="${BASH_REMATCH[1]}"
				module_factoids_lock "$(tr '[:upper:]' '[:lower:]' <<< "$key")"
				send_msg "$channel" "Ok $(parse_hostmask_nick "$sender"), the factoid \"$key\" is now protected from changes"
			else
				feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "lock" "key"
			fi
		else
			access_fail "$sender" "lock a factoid" "factoid_admin"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "unlock factoid")"; then
		if access_check_capab "factoid_admin" "$sender" "GLOBAL"; then
			if [[ "$parameters" =~ ^(.+) ]]; then
				local key="${BASH_REMATCH[1]}"
				module_factoids_unlock "$(tr '[:upper:]' '[:lower:]' <<< "$key")"
				send_msg "$channel" "Ok $(parse_hostmask_nick "$sender"), the factoid \"$key\" is no longer protected from changes"
			else
				feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "lock" "key"
			fi
		else
			access_fail "$sender" "lock a factoid" "factoid_admin"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "whatis")"; then
		if [[ "$parameters" =~ ^(.+) ]]; then
			local key="${BASH_REMATCH[1]}"
			module_factoids_send_factoid "$channel" "$key"
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "whatis" "key"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "factoid stats")"; then
		local count="$(module_factoids_get_count)"
		local lockedcount="$(module_factoids_get_locked_count)"
		if [[ "$count" ]]; then
			send_msg "$channel" "There are $count items in my factoid database. $lockedcount of the factoids are locked."
		fi
		return 1
	elif [[ "$query" =~ ^((what|where|who|why|how)\ )?((is|are|were|to)\ )?([^\?]+)\?? ]]; then
		local key="${BASH_REMATCH[@]: -1}"
		local value="$(module_factoids_SELECT "$(tr '[:upper:]' '[:lower:]' <<< "$key")")"
		if [[ "$value" ]]; then
			module_factoids_send_factoid "$channel" "$key"
			return 1
		fi
	fi
	return 0
}
