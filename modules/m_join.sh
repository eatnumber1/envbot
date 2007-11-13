#!/bin/bash
# -*- coding: utf-8 -*-
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
## Join/part
#---------------------------------------------------------------------

module_join_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	commands_register "$1" 'join' || return 1
	commands_register "$1" 'part' || return 1
}

module_join_UNLOAD() {
	return 0
}

module_join_REHASH() {
	return 0
}

module_join_handler_part() {
	local sender="$1"
	local parameters="$3"
	if [[ "$parameters" =~ ^(#[^ ]+)(\ (.+))? ]]; then
		local channel="${BASH_REMATCH[1]}"
		local reason="${BASH_REMATCH[3]}"
		if access_check_capab "join" "$sender" "$channel"; then
			if [[ -z "$reason" ]]; then
				channels_part "$channel"
			else
				channels_part "$channel" "$reason"
			fi
		else
			access_fail "$sender" "make the bot part channel" "join"
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "part" "<#channel> [<reason>]"
	fi
}

module_join_handler_join() {
	local sender="$1"
	local parameters="$3"
	if [[ "$parameters" =~ ^(#[^ ]+)(\ [^ ]+)? ]]; then
		local channel="${BASH_REMATCH[1]}"
		local key="${BASH_REMATCH[2]}"
		if access_check_capab "join" "$sender" "$channel"; then
			key="${key## }"
			if [[ -z "$key" ]]; then
				channels_join "${channel}"
			else
				channels_join "${channel}" "$key"
			fi
		else
			access_fail "$sender" "make the join channel" "join"
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "join" "<#channel> [<key>]"
	fi
}
