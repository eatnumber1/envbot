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
# Simple FAQ module

module_factoids_INIT() {
	echo "after_load on_PRIVMSG"
}

module_factoids_UNLOAD() {
	unset module_factoids_clean_string module_factoids_set
	unset module_factoids_SELECT module_factoids_INSERT module_factoids_UPDATE module_factoids_DELETE
	unset module_factoids_after_load module_factoids_on_PRIVMSG
}

module_faq_REHASH() {
	return 0
}


# Make string safe for SQL.
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

# Change the value
module_factoids_UPDATE() {
	sqlite3 -list "$config_module_factoids_database" \
		"UPDATE factoids SET value='$(module_factoids_clean_string "$2")' WHERE name='$(module_factoids_clean_string "$1")';"
}

module_factoids_DELETE() {
	echo "$(sqlite3 -list "$config_module_factoids_database" \
		"DELETE FROM factoids WHERE name='$(module_factoids_clean_string "$1")';")"
}

# Wrapper, call either INSERT or UPDATE
# $1 = key
# $2 = value
module_factoids_set() {
	if [[ $(module_factoids_SELECT "$1") ]]; then
		module_factoids_UPDATE "$1" "$2"
	else
		module_factoids_INSERT "$1" "$2"
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
		if [[ "$parameters" =~ ^([^ ]+)\ as\ (.*) ]]; then
			local key="${BASH_REMATCH[1]}"
			local value="${BASH_REMATCH[2]}"
			module_factoids_set "$key" "$value"
			return 1
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "learn" "key value"
		fi
	elif parameters="$(parse_query_is_command "$query" "forget")"; then
		if [[ "$parameters" =~ ^([^ ]+) ]]; then
			local key="${BASH_REMATCH[1]}"
			module_factoids_DELETE "$key"
			return 1
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "forget" "key"
		fi
	elif parameters="$(parse_query_is_command "$query" "whatis")"; then
		if [[ "$parameters" =~ ^([^ ]+) ]]; then
			local key="${BASH_REMATCH[1]}"
			local value="$(module_factoids_SELECT "$key")"
			if [[ $(module_factoids_SELECT "$1") ]]; then
				send_msg "$channel" "$key is $value"
			else
				send_msg "$channel" "I don't know what \"$key\" is."
			fi
			return 1
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "whatis" "key"
		fi
	fi
	if [[ "$query" =~ ^((what|where|who|why|how)\ )?((is|are|were|to)\ )?([^ \?]+)\?? ]]; then
		local key="${BASH_REMATCH[@]: -1}"
		local value="$(module_factoids_SELECT "$key")"
		if [[ "$value" ]]; then
			send_msg "$channel" "$key is $value"
			return 1
		fi
	fi
	return 0
}
