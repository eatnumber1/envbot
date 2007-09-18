#!/bin/bash
###########################################################################
#                                                                         #
#   Copyright (c)                                                         #
#     Arvid Norlander <anmaster@kuonet.org>                               #
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
# Allow owners to make to bot say something

module_say_INIT() {
	echo "on_PRIVMSG"
}

module_say_UNLOAD() {
	unset module_say_on_PRIVMSG
}

module_say_REHASH() {
	return 0
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_say_on_PRIVMSG() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local channel="$2"
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "say")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ (.*) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local message="${BASH_REMATCH[2]}"
			if access_check_owner "$sender"; then
				send_msg "$channel" "$message"
				sleep 1
			else
				access_fail "$sender" "make the bot talk with say" "owner"
			fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "say" "target message # Where target is a nick or channel"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "act")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ (.*) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local message="${BASH_REMATCH[2]}"
			if access_check_owner "$sender"; then
				send_ctcp "${channel}" "ACTION ${message}"
				sleep 1
			else
				access_fail "$sender" "make the bot act" "owner"
			fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "act" "target message # Where target is a nick or channel"
		fi
		return 1
	fi
	return 0
}
