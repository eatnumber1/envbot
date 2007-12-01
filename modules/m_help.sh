#!/bin/bash
# -*- coding: utf-8 -*-
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

module_help_INIT() {
	modinit_API='2'
	commands_register "$1" 'help' || return 1
	helpentry_help_help_syntax='<command>'
	helpentry_help_help_description='Displays help for <command>'
}

module_help_UNLOAD() {
	unset read_module_data fetch_module_data
}

module_help_REHASH() {
	return 0
}

fetch_module_data() {
	local module_name="$1"
	local function_name="$2"
	local target_syntax="$3"
	local target_description="$4"
	
	local varname_syntax="helpentry_${module_name}_${function_name}_syntax"
	local varname_description="helpentry_${module_name}_${function_name}_description"
	if [[ -z ${!varname_syntax} || -z ${!varname_description} ]]; then
		return 1
	fi
	printf -v "$target_syntax" '%s' "${!varname_syntax}" 
	printf -v "$target_description" '%s' "${!varname_description}"
}

module_help_handler_help() {
	local sender="$1"
	local parameters="$3"
	if [[ $parameters =~ ^([a-zA-Z0-9][^ ]*)( [^ ]+)? ]]; then
		local command_name="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
		# Look where we will reply to. We will not reply in the channel, even if the request was made in a channel
		local target
		parse_hostmask_nick "$sender" 'target'
		# Get the module name the command belongs to.
		local module_name=
		commands_provides "$command_name" 'module_name'
		# Extract the function name.
		local function_name=
		hash_get 'commands_list' "$command_name" 'function_name'
		if [[ $function_name =~ ^module_${module_name}_handler_(.+)$ ]]; then
			function_name="${BASH_REMATCH[1]}"
		fi
		# Finally get the data for a specific function in specific module.
		local syntax=
		local description=
		fetch_module_data "$module_name" "$function_name" syntax description || {
			send_msg "$target" "Sorry, no help for ${format_bold}${command_name}${format_bold}"
			return
		}
		# And send it back to the user.
		send_msg "$target" "${format_bold}${command_name}${format_bold} $syntax"
		send_msg "$target" "$description"
	else
		local sendernick=
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "help" "<command>"
	fi
}
