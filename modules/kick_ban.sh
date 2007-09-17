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

module_kick_ban_INIT() {
	echo "on_PRIVMSG"
}

module_kick_ban_UNLOAD() {
	unset module_assign_mode_on_PRIVMSG
}

module_kick_ban_REHASH() {
	return 0
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel)
# $3 = nick
module_kick_ban_on_PRIVMSG() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local sendon_channel="$2"
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "kick")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ ([^ ]+)\ (.*) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local nick="${BASH_REMATCH[2]}"
			local kickmessage="${BASH_REMATCH[3]}"
			if access_check_owner "$sender"; then
				send_raw "KICK $channel $nick $kickmessage"
				log_stdout "$nick kicked from $channel with kick message: $kickmessage"
			else
				access_fail "$sender" "make the bot kick somebody" "owner"
			fi
			return 1
		fi
	elif parameters="$(parse_query_is_command "$query" "ban")"; then
		if [[ "$parameters" =~ ^([^ ]+)\ ([^ ]+) ]]; then
			local channel="${BASH_REMATCH[1]}"
			local nick="${BASH_REMATCH[2]}"
			if access_check_owner "$sender"; then
				send_modes "$channel" "+b $nick"
				# send_modes "$channel" "+b" get_hostmask $nick <-- not implemented yet
				log_stdout "$nick banned from $channel"
			else
				access_fail "$sender" "make the bot ban somebody" "owner"
			fi
			return 1
		fi
	fi

	return 0
}
