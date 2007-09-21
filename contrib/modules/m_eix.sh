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
# Check eix and return output from it.

module_eix_INIT() {
	echo "on_PRIVMSG after_load"
}

module_eix_UNLOAD() {
	unset module_eix_format_string
	unset module_eix_on_PRIVMSG module_eix_after_load
}

module_eix_REHASH() {
	return 0
}

# Called after module has loaded.
# Loads FAQ items
module_eix_after_load() {
	# Check (silently) for sqlite3
	type -p eix &> /dev/null
	if [[ $? -ne 0 ]]; then
		log_stdout "Couldn't find eix command line tool. The eix module depend on that tool."
		return 1
	fi
}

# eix format string:
module_eix_format_string='<category>/<name> \(<bestslots>\) \(<homepage>\): <description>'

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_eix_on_PRIVMSG() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local channel="$2"
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "eix")"; then
		if [[ "$parameters" =~ ^([^ ]+) ]]; then
			local pattern="${BASH_REMATCH[1]}"
				log_to_file eix.log "$sender made the bot run eix on \"$pattern\""
				send_msg "$channel" "$(eix -ps --format "$module_eix_format_string" "$pattern" | head -n 1)"
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "eix" "pattern"
		fi
		return 1
	fi
	return 0
}
