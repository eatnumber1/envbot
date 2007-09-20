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
# THIS IS FOR DEBUGGING!
# Allow owners to make bot send any line.

module_sendraw_INIT() {
	echo "on_PRIVMSG"
}

module_sendraw_UNLOAD() {
	unset module_sendraw_on_PRIVMSG
}

module_sendraw_REHASH() {
	return 0
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_sendraw_on_PRIVMSG() {
	# Accept anywhere
	local sender="$1"
	local channel="$2"
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "raw")"; then
		if access_check_owner "$sender"; then
			send_raw "$parameters"
		else
			access_fail "$sender" "send a raw line" "owner"
		fi
		return 1
	fi
	return 0
}
