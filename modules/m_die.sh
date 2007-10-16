#!/bin/bash
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007  Arvid Norlander                                    #
#  Copyright (C) 2007  EmErgE <halt.system@gmail.com>                     #
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
## Quit the bot.
#---------------------------------------------------------------------

module_die_INIT() {
	echo 'on_PRIVMSG'
}

module_die_UNLOAD() {
	return 0
}

module_die_REHASH() {
	return 0
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_die_on_PRIVMSG() {
	local sender="$1"
	local query="$3"
	local parameters
	if parse_query_is_command 'parameters' "$query" "die"; then
		if access_check_owner "$sender"; then
			access_log_action "$sender" "made the bot die with reason: $parameters"
			bot_quit "$parameters"
		else
			access_fail "$sender" "make the bot die" "owner"
		fi
		return 1
	elif parse_query_is_command 'parameters' "$query" "restart"; then
		if access_check_owner "$sender"; then
			access_log_action "$sender" "made the bot restart with reason: $parameters"
			bot_restart "$parameters"
		else
			access_fail "$sender" "make the bot restart" "owner"
		fi
		return 1
	fi
	return 0
}
