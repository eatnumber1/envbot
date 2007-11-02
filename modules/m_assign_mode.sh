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
## Channel modes
#---------------------------------------------------------------------

module_assign_mode_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	commands_register "$1" 'op'        || return 1
	commands_register "$1" 'deop'      || return 1
	commands_register "$1" 'halfop'    || return 1
	commands_register "$1" 'dehalfop'  || return 1
	commands_register "$1" 'voice'     || return 1
	commands_register "$1" 'devoice'   || return 1
	commands_register "$1" 'protect'   || return 1
	commands_register "$1" 'deprotect' || return 1
	commands_register "$1" 'topic'     || return 1

}

module_assign_mode_UNLOAD() {
	return 0
}

module_assign_mode_REHASH() {
	return 0
}

module_assign_mode_handler_op() {
	local sender="$1"
	local sendon_channel="$2"
	local parameters="$3"
	if [[ "$parameters" =~ ^(#[^ ]+)\ ([^ ]+) ]]; then
		local channel="${BASH_REMATCH[1]}"
		local nick="${BASH_REMATCH[2]}"
		if access_check_capab "op" "$sender" "$channel"; then
			send_modes "$channel" "+o $nick"
		else
			access_fail "$sender" "make the bot op somebody" "op"
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "op" "<#channel> <nick>"
	fi
}

module_assign_mode_handler_deop() {
	local sender="$1"
	local sendon_channel="$2"
	local parameters="$3"
	if [[ "$parameters" =~ ^(#[^ ]+)\ ([^ ]+) ]]; then
		local channel="${BASH_REMATCH[1]}"
		local nick="${BASH_REMATCH[2]}"
		if access_check_capab "op" "$sender" "$channel"; then
			send_modes "$channel" "-o $nick"
		else
			access_fail "$sender" "make the bot deop somebody" "op"
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "deop" "<#channel> <nick>"
	fi
}

module_assign_mode_handler_halfop() {
	local sender="$1"
	local sendon_channel="$2"
	local parameters="$3"
	if [[ "$parameters" =~ ^(#[^ ]+)\ ([^ ]+) ]]; then
		local channel="${BASH_REMATCH[1]}"
		local nick="${BASH_REMATCH[2]}"
		if access_check_capab "halfop" "$sender" "$channel"; then
				send_modes "$channel" "+h $nick"
		else
			access_fail "$sender" "make the bot halfop somebody" "halfop"
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "halfop" "<#channel> <nick>"
	fi
}

module_assign_mode_handler_dehalfop() {
	local sender="$1"
	local sendon_channel="$2"
	local parameters="$3"
	if [[ "$parameters" =~ ^(#[^ ]+)\ ([^ ]+) ]]; then
		local channel="${BASH_REMATCH[1]}"
		local nick="${BASH_REMATCH[2]}"
		if access_check_capab "halfop" "$sender" "$channel"; then
			send_modes "$channel" "-h $nick"
		else
			access_fail "$sender" "make the bot dehalfop somebody" "halfop"
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "dehalfop" "<#channel> <nick>"
	fi
}

module_assign_mode_handler_voice() {
	local sender="$1"
	local sendon_channel="$2"
	local parameters="$3"
	if [[ "$parameters" =~ ^(#[^ ]+)\ ([^ ]+) ]]; then
		local channel="${BASH_REMATCH[1]}"
		local nick="${BASH_REMATCH[2]}"
		if access_check_capab "voice" "$sender" "$channel"; then
			send_modes "$channel" "+v $nick"
		else
			access_fail "$sender" "make the bot give voice to somebody" "voice"
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "voice" "<#channel> <nick>"
	fi
}

module_assign_mode_handler_devoice() {
	local sender="$1"
	local sendon_channel="$2"
	local parameters="$3"
	if [[ "$parameters" =~ ^(#[^ ]+)\ ([^ ]+) ]]; then
		local channel="${BASH_REMATCH[1]}"
		local nick="${BASH_REMATCH[2]}"
		if access_check_capab "voice" "$sender" "$channel"; then
			send_modes "$channel" "-v $nick"
		else
			access_fail "$sender" "make the bot take voice from somebody" "voice"
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "devoice" "<#channel> <nick>"
	fi
}

module_assign_mode_handler_protect() {
	local sender="$1"
	local sendon_channel="$2"
	local parameters="$3"
	if [[ "$parameters" =~ ^(#[^ ]+)\ ([^ ]+) ]]; then
		local channel="${BASH_REMATCH[1]}"
		local nick="${BASH_REMATCH[2]}"
		if access_check_capab "protect" "$sender" "$channel"; then
			send_modes "$channel" "+a $nick"
		else
			access_fail "$sender" "make the bot protect somebody" "protect"
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "protect" "<#channel> <nick>"
	fi
}

module_assign_mode_handler_deprotect() {
	local sender="$1"
	local sendon_channel="$2"
	local parameters="$3"
	if [[ "$parameters" =~ ^(#[^ ]+)\ ([^ ]+) ]]; then
		local channel="${BASH_REMATCH[1]}"
		local nick="${BASH_REMATCH[2]}"
		if access_check_capab "protect" "$sender" "$channel"; then
			send_modes "$channel" "-a $nick"
		else
			access_fail "$sender" "make the bot deprotect somebody" "protect"
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "deprotect" "<#channel> <nick>"
	fi
}

module_assign_mode_handler_topic() {
	local sender="$1"
	local sendon_channel="$2"
	local parameters="$3"
	if [[ "$parameters" =~ ^(#[^ ]+)\ (.+) ]]; then
		local channel="${BASH_REMATCH[1]}"
		local message="${BASH_REMATCH[2]}"
		if access_check_capab "topic" "$sender" "$channel"; then
			send_topic "$channel" "$message"
		else
			access_fail "$sender" "make the bot protect somebody" "topic"
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "topic" "<#channel> <topic>"
	fi
}
