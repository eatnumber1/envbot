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
## Allow owners to make to bot say something
#---------------------------------------------------------------------

module_say_INIT() {
	echo 'on_PRIVMSG'
}

module_say_UNLOAD() {
	return 0
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
	local sender="$1"
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "say")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ (.+) ]]; then
			local target="${BASH_REMATCH[1]}"
			local message="${BASH_REMATCH[2]}"
			local scope
			# Is it a channel?
			if [[ $target =~ ^# ]]; then
				scope="$target"
			else
				scope="MSG"
			fi
			if access_check_capab "say" "$sender" "$scope"; then
				access_log_action "$sender" "made the bot say \"$message\" in/to \"$target\""
				send_msg "$target" "$message"
			else
				access_fail "$sender" "make the bot talk with say" "say"
			fi
		else
			local sendernick
			parse_hostmask_nick "$sender" 'sendernick'
			feedback_bad_syntax "$sendernick" "say" "target message # Where target is a nick or channel"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "act")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ (.+) ]]; then
			local target="${BASH_REMATCH[1]}"
			local message="${BASH_REMATCH[2]}"
			local scope
			# Is it a channel?
			if [[ $target =~ ^# ]]; then
				scope="$target"
			else
				scope="MSG"
			fi
			if access_check_capab "say" "$sender" "$scope"; then
				access_log_action "$sender" "made the bot act \"$message\" in/to \"$target\""
				send_ctcp "$target" "ACTION ${message}"
			else
				access_fail "$sender" "make the bot act" "say"
			fi
		else
			local sendernick
			parse_hostmask_nick "$sender" 'sendernick'
			feedback_bad_syntax "$sendernick" "act" "target message # Where target is a nick or channel"
		fi
		return 1
	fi
	return 0
}
