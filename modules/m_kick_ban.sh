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
## Kicking and banning.
#---------------------------------------------------------------------

module_kick_ban_INIT() {
	modinit_API='2'
	modinit_HOOKS='after_load after_connect after_load on_numeric periodic'
	commands_register "$1" 'kick'
	commands_register "$1" 'ban'
}

module_kick_ban_UNLOAD() {
	unset module_kick_ban_TBAN_supported module_kick_ban_timed_bans
	unset module_kick_ban_next_unset module_kick_ban_store_ban

}

module_kick_ban_REHASH() {
	return 0
}

module_kick_ban_after_load() {
	unset module_kick_ban_next_unset module_kick_ban_timed_bans
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

module_kick_ban_periodic() {
	# We got some ban to process
	if [[ $module_kick_ban_next_unset ]] && (( $envbot_time >= $module_kick_ban_next_unset )); then
		local nextban
		local index time channel mask
		for index in ${!module_kick_ban_timed_bans[*]}; do
			read -r time channel mask <<< "${module_kick_ban_timed_bans[${index}]}"
			# Should we unset?
			if (( $envbot_time >= $time )); then
				# TODO: Queue them?
				send_modes "$channel" "-b $mask"
				# Remove ban from list.
				unset "module_kick_ban_timed_bans[${index}]"
				continue
			# Next ban?
			elif [[ -z $nextban ]] || [[ $nextban -gt $time ]]; then
				nextban="$time"
			fi
		done
		# Note time for next ban (if any)
		if [[ $nextban ]]; then
			module_kick_ban_next_unset="$nextban"
		else
			unset module_kick_ban_next_unset
		fi
	fi
}

#---------------------------------------------------------------------
## Store a ban
## @Type Private
## @param Channel
## @param Banmask
## @param Duration
#---------------------------------------------------------------------
module_kick_ban_store_ban() {
	# Calculate unset-time
	local targettime="$3"
	(( targettime += $envbot_time ))

	module_kick_ban_timed_bans+=( "$targettime $1 $2" )
	if [[ -z $module_kick_ban_next_unset ]] || [[ $module_kick_ban_next_unset -gt $targettime ]]; then
		module_kick_ban_next_unset="$targettime"
	fi
}


module_kick_ban_handler_kick() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local sendon_channel="$2"
	local parameters="$3"
	if [[ $parameters =~ ^((#[^ ]+)\ )(.*) ]]; then
		local channel="${BASH_REMATCH[2]}"
		parameters="${BASH_REMATCH[3]}"
	else
		if ! [[ $channel =~ ^# ]]; then
			if [[ $sendon_channel =~ ^# ]]; then
				local channel="$sendon_channel"
			else
				local sendernick
				parse_hostmask_nick "$sender" 'sendernick'
				feedback_bad_syntax "$sendernick" "kick" "[#channel] nick reason # Channel must be send when the message is not sent in a channel"
				return 0
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
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "kick" "[#channel] nick reason # Channel must be send when the message is not sent in a channel"
	fi
}

module_kick_ban_handler_ban() {
	local sender="$1"
	local sendon_channel="$2"
	local parameters="$3"
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
					module_kick_ban_store_ban "$channel" "$nick" "$duration"
				fi
			else
				send_modes "$channel" "+b $nick"
			fi
			access_log_action "$sender" "banned $nick from $channel"
		else
			access_fail "$sender" "make the bot ban somebody" "ban"
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "ban" "#channel nick [duration]"
	fi
}
