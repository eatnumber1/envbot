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
## Simple seen module using SQLite3
#---------------------------------------------------------------------

module_seen_INIT() {
	modinit_API='2'
	modinit_HOOKS='after_load on_PRIVMSG'
	commands_register "$1" 'seen' || return 1
	helpentry_module_seen_description="Provides last seen information."

	helpentry_seen_seen_syntax='<nick>'
	helpentry_seen_seen_description='Report when the bot last saw <nick>.'
}

module_seen_UNLOAD() {
	unset module_seen_exec_sql module_seen_SELECT module_seen_INSERT module_seen_UPDATE
	unset module_seen_set_INSERT_or_UPDATE
	unset module_seen_store module_seen_find
}

module_seen_REHASH() {
	return 0
}


# Called after module has loaded.
module_seen_after_load() {
	modules_depends_register "seen" "sqlite3" || {
		# This error reporting is hackish, will fix later.
		if ! list_contains "modules_loaded" "sqlite3"; then
			log_error "The seen module depends upon the SQLite3 module being loaded."
		fi
		return 1
	}
	if [[ -z $config_module_seen_table ]]; then
		log_error "\"Seen table\" (config_module_seen_table) must be set in config."
		return 1
	fi
	if ! module_sqlite3_table_exists "$config_module_seen_table"; then
		log_error "seen module: $config_module_seen_table does not exist in the database file."
		log_error "seen module: See comment in doc/seen.sql for how to create the table."
	fi
}

#---------------------------------------------------------------------
## Get the data about nick
## @Type Private
## @param The nick
## @Stdout The result of the database query.
#---------------------------------------------------------------------
module_seen_SELECT() {
	module_sqlite3_exec_sql "SELECT timestamp, channel, message FROM $config_module_seen_table WHERE nick='$(module_sqlite3_clean_string "$1")';"
}

#---------------------------------------------------------------------
## Insert a new item into DB
## @Type Private
## @param Nick
## @param Channel
## @param Timestamp
## @param Query
#---------------------------------------------------------------------
module_seen_INSERT() {
	module_sqlite3_exec_sql \
		"INSERT INTO $config_module_seen_table (nick, channel, timestamp, message) VALUES('$(module_sqlite3_clean_string "$1")', '$(module_sqlite3_clean_string "$2")', '$(module_sqlite3_clean_string "$3")', '$(module_sqlite3_clean_string "$4")');"
}

#---------------------------------------------------------------------
## Change the item in DB
## @Type Private
## @param Nick
## @param Channel
## @param Timestamp
## @param Message
#---------------------------------------------------------------------
module_seen_UPDATE() {
	module_sqlite3_exec_sql \
		"UPDATE $config_module_seen_table SET channel='$(module_sqlite3_clean_string "$2")', timestamp='$(module_sqlite3_clean_string "$3")', message='$(module_sqlite3_clean_string "$4")' WHERE nick='$(module_sqlite3_clean_string "$1")';"
}

#---------------------------------------------------------------------
## Wrapper, call either INSERT or UPDATE
## @Type Private
## @param Nick
## @param Channel
## @param Timestamp
## @param Message
#---------------------------------------------------------------------
module_seen_set_INSERT_or_UPDATE() {
	if [[ $(module_seen_SELECT "$1") ]]; then
		module_seen_UPDATE "$1" "$2" "$3" "$4"
	else
		module_seen_INSERT "$1" "$2" "$3" "$4"
	fi
}

#---------------------------------------------------------------------
## Store a line
## @Type Private
## @param Sender
## @param Channel
## @param Timestamp
## @param Query
#---------------------------------------------------------------------
module_seen_store() {
	# Clean spaces, fastest way for this
	local query
	read -ra query <<< "$4"
	local sendernick
	parse_hostmask_nick "$1" 'sendernick'
	module_seen_set_INSERT_or_UPDATE "$(echo -n "$sendernick" | tr '[:upper:]' '[:lower:]')" "$2" "$3" "${query[*]}"
}

#---------------------------------------------------------------------
## Look up a nick and send info to a channel/nick
## @Type Private
## @param Sender
## @param Channel
## @param Nick to look up
#---------------------------------------------------------------------
module_seen_find() {
	local sender="$1"
	local channel="$2"
	local nick="$(tr '[:upper:]' '[:lower:]' <<< "$3")"
	local sender_nick=
	parse_hostmask_nick "$sender" 'sender_nick'
	# Classical ones. We just HAVE to do them.
	if [[ "$nick" == "$(tr '[:upper:]' '[:lower:]' <<< "$server_nick_current")" ]]; then
		send_msg "$channel" "$sender_nick, you found me!"
		return 0
	elif [[ "$nick" == "$(tr '[:upper:]' '[:lower:]' <<< "$sender_nick")" ]]; then
		send_ctcp "$channel" "ACTION holds up a mirror for $sender_nick"
		return 0
	fi
	local match="$(module_seen_SELECT "$nick")"
	if [[ $match ]]; then
		# So we got a match
		# Lets use regex
		if [[ $match =~ ([0-9]+)\|(#[^ |]+)\|(.*) ]]; then
			local found_timestamp="${BASH_REMATCH[1]}"
			local found_channel="${BASH_REMATCH[2]}"
			local found_message="${BASH_REMATCH[3]}"
			if [[ $found_message =~ ^ACTION\ (.*) ]]; then
				found_message="* $3 ${BASH_REMATCH[1]}"
			fi
			local difference frmtdiff
			time_get_current 'difference'
			(( difference -= found_timestamp ))
			time_format_difference "$difference" 'frmtdiff'
			send_msg "$channel" "$3 was last seen $frmtdiff ago in $found_channel saying \"$found_message\""
		fi
	else
		send_msg "$channel" "Sorry, I have not seen $3."
	fi
}

module_seen_on_PRIVMSG() {
	local sender="$1"
	local channel="$2"
	local query="$3"
	# If in channel, store
	if [[ $channel =~ ^# ]]; then
		local now=
		time_get_current 'now'
		module_seen_store "$sender" "$channel" "$now" "$query"
	# If not in channel respond to any commands in /msg
	else
		parse_hostmask_nick "$sender" 'channel'
	fi
}

module_seen_handler_seen() {
	local sender="$1"
	local channel="$2"
	if ! [[ $2 =~ ^# ]]; then
		parse_hostmask_nick "$sender" 'channel'
	fi
	# Lets look up messages
	local parameters="$3"
	if [[ "$parameters" =~ ^([^ ]+) ]]; then
		local nick="${BASH_REMATCH[1]}"
		module_seen_find "$sender" "$channel" "$nick"
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "seen" "<nick>"
	fi
}
