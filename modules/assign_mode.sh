#!/bin/bash
###########################################################################
#                                                                         #
#   Copyright (c)                                                         #
#     Arvid Norlander <anmaster@kuonet.org>                               #
#     EmErgE <halt.system@gmail.com>                                      #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
###########################################################################
# Channel modes

module_assign_mode_INIT() {
	echo "on_PRIVMSG"
}

module_assign_mode_UNLOAD() {
	unset module_assign_mode_on_PRIVMSG
}

module_assign_mode_REHASH() {
	return 0
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel)
# $3 = nick
module_assign_mode_on_PRIVMSG() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local sendon_channel="$2"
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "op")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ ([^ ]+) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local nick="${BASH_REMATCH[2]}"
			if access_check_owner "$sender"; then
				send_raw "MODE $channel +o $nick"
			else
				access_fail "$sender" "make the bot op somebody" "owner"
			fi
			return 1
		fi
	elif parameters="$(parse_query_is_command "$query" "deop")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ ([^ ]+) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local nick="${BASH_REMATCH[2]}"
			if access_check_owner "$sender"; then
				send_raw "MODE $channel -o $nick"
			else
				access_fail "$sender" "make the bot deop somebody" "owner"
			fi
			return 1
		fi
	elif parameters="$(parse_query_is_command "$query" "halfop")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ ([^ ]+) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local nick="${BASH_REMATCH[2]}"
			if access_check_owner "$sender"; then
					send_raw "MODE $channel +h $nick"
			else
				access_fail "$sender" "make the bot halfop somebody" "owner"
			fi
			return 1
		fi
	elif parameters="$(parse_query_is_command "$query" "dehalfop")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ ([^ ]+) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local nick="${BASH_REMATCH[2]}"
			if access_check_owner "$sender"; then
				send_raw "MODE $channel -h $nick"
			else
				access_fail "$sender" "make the bot dehalfop somebody" "owner"
			fi
			return 1
		fi
	elif parameters="$(parse_query_is_command "$query" "voice")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ ([^ ]+) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local nick="${BASH_REMATCH[2]}"
			if access_check_owner "$sender"; then
				send_raw "MODE $channel +v $nick"
			else
				access_fail "$sender" "make the bot give voice to somebody" "owner"
			fi
			return 1
		fi
	elif parameters="$(parse_query_is_command "$query" "devoice")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ ([^ ]+) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local nick="${BASH_REMATCH[2]}"
			if access_check_owner "$sender"; then
				send_raw "MODE $channel -v $nick"
			else
				access_fail "$sender" "make the bot take voice from somebody" "owner"
			fi
			return 1
		fi
	elif parameters="$(parse_query_is_command "$query" "protect")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ ([^ ]+) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local nick="${BASH_REMATCH[2]}"
			if access_check_owner "$sender"; then
				send_raw "MODE $channel +a $nick"
			else
				access_fail "$sender" "make the bot protect somebody" "owner"
			fi
			return 1
		fi
	elif parameters="$(parse_query_is_command "$query" "deprotect")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ ([^ ]+) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local nick="${BASH_REMATCH[2]}"
			if access_check_owner "$sender"; then
				send_raw "MODE $channel -a $nick"
			else
				access_fail "$sender" "make the bot deprotect somebody" "owner"
			fi
			return 1
		fi
	elif parameters="$(parse_query_is_command "$query" "topic")"; then
		if [[ "$parameters" =~ ^(#[^ ]+)\ (.*) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local message="${BASH_REMATCH[2]}"
			if access_check_owner "$sender"; then
				send_raw "TOPIC $channel :$message"
			else
				access_fail "$sender" "make the bot protect somebody" "owner"
			fi
			return 1
		fi
	fi

	return 0
}
