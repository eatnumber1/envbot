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
	echo "after_load on_PRIVMSG"
}

module_factoids_UNLOAD() {
	unset module_factoids_clean_string module_factoids_set module_factoids_set_SELECT_or_UPDATE
	unset module_factoids_remove module_factoids_is_locked module_factoids_lock module_factoids_unlock
	unset module_factoids_SELECT module_factoids_INSERT module_factoids_UPDATE module_factoids_DELETE
	unset module_factoids_after_load module_factoids_on_PRIVMSG
}

module_faq_REHASH() {
	return 0
}


# Make string safe for SQL.
# Yes we just discard quotes atm.
module_factoids_clean_string() {
	tr -Cd 'A-Za-z0-9 ,;.:-_<>*|~^!"#%&/()=?+\@${}[]+' <<< "$1"
}

# Get an item from DB
# $1 = key
module_factoids_SELECT() {
	#$ sqlite3 -list data/factoids.sqlite "SELECT value from factoids WHERE name='factoids';"
	#A system that stores useful bits of information
	echo "$(sqlite3 -list "$config_module_factoids_database" \
		"SELECT value FROM factoids WHERE name='$(module_factoids_clean_string "$1")';")"
}

# Insert a new item into DB
# $1 = key
# $2 = value
module_factoids_INSERT() {
	sqlite3 -list "$config_module_factoids_database" \
		"INSERT INTO factoids (name, value) VALUES('$(module_factoids_clean_string "$1")', '$(module_factoids_clean_string "$2")');"
}

# Change the item in DB
# $1 = key
# $2 = new value
module_factoids_UPDATE() {
	sqlite3 -list "$config_module_factoids_database" \
		"UPDATE factoids SET value='$(module_factoids_clean_string "$2")' WHERE name='$(module_factoids_clean_string "$1")';"
}

# Remove an item
# $1 = key
module_factoids_DELETE() {
	sqlite3 -list "$config_module_factoids_database" \
		"DELETE FROM factoids WHERE name='$(module_factoids_clean_string "$1")';"
}

# Check if factoid is locked or not.
# $1 = key
# Return 0 = locked
#        1 = not locked
module_factoids_is_locked() {
	local lock="$(sqlite3 -list "$config_module_factoids_database" \
		"SELECT is_locked FROM factoids WHERE name='$(module_factoids_clean_string "$1")';")"
	if [[ $lock == "1" ]]; then
		return 0
	else
		return 1
	fi
}

# Lock a factoid against changes from non-owners
# $1 = key
module_factoids_lock() {
	sqlite3 -list "$config_module_factoids_database" \
		"UPDATE factoids SET is_locked='1' WHERE name='$(module_factoids_clean_string "$1")';"
}

# Unlock a factoid from protection against non-owners
# $1 = key
module_factoids_unlock() {
	sqlite3 -list "$config_module_factoids_database" \
		"UPDATE factoids SET is_locked='0' WHERE name='$(module_factoids_clean_string "$1")';"
}

# Wrapper, call either INSERT or UPDATE
# $1 = key
# $2 = value
module_factoids_set_SELECT_or_UPDATE() {
	if [[ $(module_factoids_SELECT "$1") ]]; then
		module_factoids_UPDATE "$1" "$2"
	else
		module_factoids_INSERT "$1" "$2"
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
		if access_check_owner "$sender"; then
			module_factoids_set_SELECT_or_UPDATE "$key" "$value"
			send_msg "$channel" "Ok $(parse_hostmask_nick "$sender"), I will remember, $key is $value"
		else
			access_fail "$sender" "change a locked faq item" "owner"
		fi
	else
		module_factoids_set_SELECT_or_UPDATE "$key" "$value"
		send_msg "$channel" "Ok $(parse_hostmask_nick "$sender"), I will remember, $key is $value"
	fi
}

# Wrapper, check access
# $1 = key
# $2 = sender
# $3 = channel
module_factoids_remove() {
	if module_factoids_is_locked "$1"; then
		if access_check_owner "$2"; then
			module_factoids_DELETE "$1"
			send_msg "$channel" "I forgot $key"
		else
			access_fail "$sender" "remove a locked faq item" "owner"
		fi
	else
		module_factoids_DELETE "$1"
		send_msg "$channel" "I forgot $key"
	fi
}


# Called after module has loaded.
# Loads FAQ items
module_factoids_after_load() {
	# Check (silently) for sqlite3
	type -p sqlite3 &> /dev/null
	if [[ $? -ne 0 ]]; then
		log_stdout "Couldn't find sqlite3 command line tool. The factoids module depend on that tool."
		return 1
	fi
	if ! [[ -r $config_module_factoids_database ]]; then
		log_stdout "Factiods database file doesn't exist or can't be read!"
		return 1
	fi
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_factoids_on_PRIVMSG() {
	# Only respond in channel.
	[[ $2 =~ ^# ]] || return 0
	local sender="$1"
	local channel="$2"
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "learn")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ (as|is|=)\ (.*) ]]; then
			local key="${BASH_REMATCH[1]}"
			local value="${BASH_REMATCH[3]}"
			module_factoids_set "$key" "$value" "$sender" "$channel"
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "learn" "key (as|is|was|=) value"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "forget")"; then
		if [[ "$parameters" =~ ^([^ ]+) ]]; then
			local key="${BASH_REMATCH[1]}"
			module_factoids_remove "$key" "$sender" "$channel"
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "forget" "key"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "lock factoid")"; then
		if access_check_owner "$sender"; then
			if [[ "$parameters" =~ ^([^ ]+) ]]; then
				local key="${BASH_REMATCH[1]}"
				module_factoids_lock "$key"
				send_msg "$channel" "Ok $(parse_hostmask_nick "$sender"), $key is now protected from changes"
			else
				feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "lock" "key"
			fi
		else
			access_fail "$sender" "lock a factoid" "owner"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "unlock factoid")"; then
		if access_check_owner "$sender"; then
			if [[ "$parameters" =~ ^([^ ]+) ]]; then
				local key="${BASH_REMATCH[1]}"
				module_factoids_unlock "$key"
				send_msg "$channel" "Ok $(parse_hostmask_nick "$sender"), $key is no longer protected from changes"
			else
				feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "lock" "key"
			fi
		else
			access_fail "$sender" "lock a factoid" "owner"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "whatis")"; then
		if [[ "$parameters" =~ ^([^ ]+) ]]; then
			local key="${BASH_REMATCH[1]}"
			local value="$(module_factoids_SELECT "$key")"
			if [[ "$value" ]]; then
				send_msg "$channel" "$key is $value"
			else
				send_msg "$channel" "I don't know what \"$key\" is."
			fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "whatis" "key"
		fi
		return 1
	elif [[ "$query" =~ ^((what|where|who|why|how)\ )?((is|are|were|to)\ )?([^ \?]+)\?? ]]; then
		local key="${BASH_REMATCH[@]: -1}"
		local value="$(module_factoids_SELECT "$key")"
		if [[ "$value" ]]; then
			send_msg "$channel" "$key is $value"
			return 1
		fi
	fi
	return 0
}
