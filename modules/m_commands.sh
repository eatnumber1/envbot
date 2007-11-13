#!/bin/bash
# -*- coding: UTF8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007  Arvid Norlander                                    #
#  Copyright (C) 2007  Vsevolod Kozlov                                    #
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
## Command-related utility commands
#---------------------------------------------------------------------

module_commands_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	commands_register "$1" 'provides' || return 1
	commands_register "$1" 'commands' || return 1
}

module_commands_UNLOAD() {
	return 0
}

module_commands_REHASH() {
	return 0
}

module_commands_handler_provides() {
	local sender="$1"
	local parameters="$3"
	if [[ $parameters =~ ^([a-zA-Z0-9][^ ]*)( [^ ]+)? ]]; then # regex suggested by AnMaster
		local command_name="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
		local target
		if [[ $2 =~ ^# ]]; then
			target="$2"
		else
			parse_hostmask_nick "$sender" 'target'
		fi
		local module_name
		commands_provides "$command_name" module_name
		if [[ -z $module_name ]]; then # No such command
			send_msg "$target" "Command \"$command_name\" does not exist."
		else
			send_msg "$target" "Command \"$command_name\" is provided by module \"$module_name\""
		fi
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "provides" "<modulename>"
	fi
}

module_commands_handler_commands() {
	local parameters="$3"
	local target
	if [[ $2 =~ ^# ]]; then
		target="$2"
	else
		parse_hostmask_nick "$1" 'target'
	fi
	if [[ -z $parameters ]]; then
		send_msg "$target" "${format_bold}Available commands${format_bold}: $commands_commands"
	else
		# So we got a parameter
		local commands_in_module
		commands_in_module "$parameters" 'commands_in_module'
		if [[ -z $commands_in_module ]]; then
			send_msg "$target" "Module \"$parameters\" does not exist or is not loaded, or provides no commands"
		else
			send_msg "$target" "${format_bold}Available commands (in module \"$parameters\")${format_bold}: $commands_in_module"
		fi
	fi
}
