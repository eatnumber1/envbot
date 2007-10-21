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
# Kicking (insert comment about Chuck Norris ;) and banning.

module_kick_ban_INIT() {
	echo 'on_PRIVMSG after_connect after_load on_numeric'
}

module_kick_ban_UNLOAD() {
	unset module_kick_ban_TBAN_supported
}

module_kick_ban_REHASH() {
	return 0
}

# Lets check if TBAN is supported
# :photon.kuonet-ng.org 461 envbot TBAN :Not enough parameters.
# :photon.kuonet-ng.org 304 envbot :SYNTAX TBAN <channel> <duration> <banmask>
module_kick_ban_after_connect() {
	module_kick_ban_TBAN_supported=0
	send_raw "TBAN"
}

# HACK: If module is loaded after connect, module_kick_ban_after_connect won't
#       get called, therefore lets check if we are connected here and check for
#       TBAN here if that is the case.
module_kick_ban_after_load() {
	if [[ $server_connected -eq 1 ]]; then
		module_kick_ban_TBAN_supported=0
		send_raw "TBAN"
	fi
}

module_kick_ban_on_numeric() {
	if [[ $1 == $numeric_ERR_NEEDMOREPARAMS ]]; then
		if [[ "$2" =~ ^TBAN\ : ]]; then
			module_kick_ban_TBAN_supported=1
		fi
	fi
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
		if [[ $parameters =~ ^((#[^ ]+)\ )(.*) ]]; then
			local channel="${BASH_REMATCH[2]}"
			parameters="${BASH_REMATCH[3]}"
		else
			if ! [[ $channel =~ ^# ]]; then
				if [[ $sendon_channel =~ ^# ]]; then
					local channel="$sendon_channel"
				else
					feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "kick" "[#channel] nick reason # Channel must be send when the message is not sent in a channel"
					return 1
				fi
			fi
		fi
		if [[ "$parameters" =~ ^([^ ]+)\ (.+) ]]; then
			local nick="${BASH_REMATCH[1]}"
			local kickmessage="${BASH_REMATCH[2]}"
			if access_check_capab "kick" "$sender" "$channel"; then
				send_raw "KICK $channel $nick :$kickmessage"
				access_log_action "$sender" "kicked $nick from $channel with kick message: $kickmessage"
			else
				access_fail "$sender" "make the bot kick somebody" "kick"
			fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "kick" "[#channel] nick reason # Channel must be send when the message is not sent in a channel"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "ban")"; then
		if [[ "$parameters" =~ ^(#[^ ]+)\ ([^ ]+)(\ ([0-9]+))? ]]; then
			local channel="${BASH_REMATCH[1]}"
			local nick="${BASH_REMATCH[2]}"
			# Optional parameter.
			local duration="${BASH_REMATCH[4]}"
			if access_check_capab "ban" "$sender" "$channel"; then
				if [[ $duration ]]; then
					# send_modes "$channel" "+b" get_hostmask $nick <-- not implemented yet
					if [[ $module_kick_ban_TBAN_supported -eq 1 ]]; then
						send_raw "TBAN $channel $duration $nick"
					else
						send_modes "$channel" "+b $nick"
						# Hackish temp fix.
						# FIXME: THIS WILL/MAY BREAK if bot get disconnected and so on.
						( sleep $duration && send_modes "$channel" "-b $nick" ) &
					fi
				else
					send_modes "$channel" "+b $nick"
				fi
				access_log_action "$sender" "banned $nick from $channel"
			else
				access_fail "$sender" "make the bot ban somebody" "ban"
			fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "ban" "#channel nick [duration]"
		fi
		return 1
	fi

	return 0
}
