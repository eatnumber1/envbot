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
# Simple seen module using sqlite3

module_seen_INIT() {
	echo "after_load on_PRIVMSG"
}

module_seen_UNLOAD() {
	unset module_seen_after_load module_seen_on_PRIVMSG
	unset module_seen_exec_sql module_seen_SELECT
	unset module_seen_store module_seen_find
}

module_seen_REHASH() {
	return 0
}


# Called after module has loaded.
# Loads FAQ items
module_seen_after_load() {
	# HACK: I should add proper dependency checking. This will break on unloading sqlite3 module
	if ! list_contains "modules_loaded" "sqlite3"; then
		log_stdout "The factoids module depends upon the SQLite3 module being loaded before it"
		return 1
	fi
	if [[ -z $config_module_seen_table ]]; then
		log_stdout "Seen table (config_module_seen_table) must be set in config."
		return 1
	fi
}

# Get the data about nick
# $1 The nick
module_seen_SELECT() {
	module_sqlite3_exec_sql "SELECT timestamp, channel, message FROM $config_module_seen_table WHERE nick='$(module_sqlite3_clean_string "$1")';"
}

# Insert a new item into DB
# $1 = nick
# $2 = channel
# $3 = timestamp
# $4 = query
module_seen_INSERT() {
	module_sqlite3_exec_sql \
		"INSERT INTO $config_module_seen_table (nick, channel, timestamp, message) VALUES('$(module_sqlite3_clean_string "$1")', '$(module_sqlite3_clean_string "$2")', '$(module_sqlite3_clean_string "$3")', '$(module_sqlite3_clean_string "$4")');"
}

# Change the item in DB
# $1 = nick
# $2 = channel
# $3 = timestamp
# $4 = message
module_seen_UPDATE() {
	module_sqlite3_exec_sql \
		"UPDATE $config_module_seen_table SET channel='$(module_sqlite3_clean_string "$2")', timestamp='$(module_sqlite3_clean_string "$3")', message='$(module_sqlite3_clean_string "$4")' WHERE nick='$(module_sqlite3_clean_string "$1")';"
}

# Wrapper, call either INSERT or UPDATE
# $1 = nick
# $2 = channel
# $3 = timestamp
# $4 = message
module_seen_set_INSERT_or_UPDATE() {
	if [[ $(module_seen_SELECT "$1") ]]; then
		module_seen_UPDATE "$1" "$2" "$3" "$4"
	else
		module_seen_INSERT "$1" "$2" "$3" "$4"
	fi
}

# Store a line
#  $1 Sender
#  $2 Channel
#  $3 Timestamp
#  $4 Query
module_seen_store() {
	local query="$(misc_clean_spaces "$4")"
	module_seen_set_INSERT_or_UPDATE "$(parse_hostmask_nick "$1" | tr '[:upper:]' '[:lower:]')" "$2" "$3" "$query"
}

module_seen_find() {
	local sender="$1"
	local channel="$2"
	local nick="$(tr '[:upper:]' '[:lower:]' <<< "$3")"
	local sender_nick="$(parse_hostmask_nick "$sender")"
	local match
	# Classical ones. We just HAVE to do them.
	if [[ "$nick" == "$(tr '[:upper:]' '[:lower:]' <<< "$server_nick_current")" ]]; then
		send_msg "$channel" "$sender_nick, you found me!"
	elif [[ "$nick" == "$(tr '[:upper:]' '[:lower:]' <<< "$sender_nick")" ]]; then
		send_ctcp "$channel" "ACTION holds up a mirror for $sender_nick"
	elif match="$(module_seen_SELECT $nick)"; then
		# So we got a match
		# Lets use regex
		if [[ $match =~ ([0-9]+)\|(#[^ |]+)\|(.*) ]]; then
			local found_timestamp="${BASH_REMATCH[1]}"
			local found_channel="${BASH_REMATCH[2]}"
			local found_message="${BASH_REMATCH[3]}"
			if [[ $found_message =~ ^ACTION\ (.*) ]]; then
				found_message="* $nick ${BASH_REMATCH[1]}"
			fi
			send_msg "$channel" "$3 was last seen on $(config_module_seen_function "$found_timestamp") in $found_channel saying \"$found_message\""
		fi
	else
		send_msg "$channel" "I have not seen $3."
	fi
}

module_seen_on_PRIVMSG() {
	# Only respond in channel.
	[[ $2 =~ ^# ]] || return 0
	local sender="$1"
	local channel="$(misc_clean_spaces "$2")"
	local query="$3"
	# Lets store messages
	module_seen_store "$sender" "$channel" "$(date -u +%s)" "$query"
	local parameters
	if parameters="$(parse_query_is_command "$query" "seen")"; then
		if [[ "$parameters" =~ ^([^ ]+) ]]; then
			local nick="${BASH_REMATCH[1]}"
			module_seen_find "$sender" "$channel" "$nick"
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "seen" "nick"
		fi
		return 1
	fi
}
