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
# Debug module, dump all variables to console.

module_dumpvars_INIT() {
	echo 'on_PRIVMSG'
}

module_dumpvars_UNLOAD() {
	return 0
}

module_dumpvars_REHASH() {
	return 0
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_dumpvars_on_PRIVMSG() {
	# Accept both in /msg and channel
	local sender="$1"
	local query="$3"
	# We don't care about parameters.
	if parse_query_is_command "$query" "dumpvars" > /dev/null; then
		if access_check_owner "$sender"; then
			# This is hackish, we only display
			# lines unique to "file" 1.
			# Also remove one variable that may fill our scrollback.
			comm -2 -3 <(declare) <(declare -f) 2>&1 | grep -Ev '^module_quote_quotes'
		else
			access_fail "$sender" "dump variables to STDOUT" "owner"
		fi
		return 1
	fi
	return 0
}
