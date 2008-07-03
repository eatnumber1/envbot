#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2008  Arvid Norlander                               #
#  Copyright (C) 2007-2008  Vsevolod Kozlov                               #
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
## Provides help command.
#---------------------------------------------------------------------

module_help_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	commands_register "$1" 'help' || return 1
	commands_register "$1" 'modinfo' || return 1
	helpentry_module_help_description="Provides help and information for commands and modules."

	helpentry_help_help_syntax='<command>'
	helpentry_help_help_description='Displays help for command <command>'

	helpentry_help_modinfo_syntax='<module>'
	helpentry_help_modinfo_description='Displays a description for module <module>'
}

module_help_UNLOAD() {
	unset module_help_fetch_module_function_data
	unset module_help_fetch_module_data
}

module_help_REHASH() {
	return 0
}

module_help_fetch_module_function_data() {
	local module_name="$1"
	local function_name="$2"
	local target_syntax="$3"
	local target_description="$4"

	local varname_syntax="helpentry_${module_name}_${function_name}_syntax"
	local varname_description="helpentry_${module_name}_${function_name}_description"
	if [[ -z ${!varname_description} ]]; then
		return 1
	fi

	printf -v "$target_description" '%s' "${!varname_description}"

	if [[ ${!varname_syntax} ]]; then
		printf -v "$target_syntax" '%s' " ${!varname_syntax}"
	fi
}

module_help_fetch_module_data() {
	local module_name="$1"
	local target_description="$2"

	local varname_description="helpentry_module_${module_name}_description"
	if [[ -z ${!varname_description} ]]; then
		return 1
	fi

	printf -v "$target_description" '%s' "${!varname_description}"
}

module_help_handler_help() {
	local sender="$1"
	local parameters="$3"
	if [[ $parameters =~ ^([a-zA-Z0-9][^ ]*)( [^ ]+)? ]]; then
		local command_name="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
		# Look where we will reply to. We will not reply in the channel, even if the request was made in a channel, unless appropriate option is set
		local target
		if [[ $2 =~ ^# && $config_module_help_reply_in_channel == 1 ]]; then
			target="$2"
		else
			parse_hostmask_nick "$sender" 'target'
		fi
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
		module_help_fetch_module_function_data "$module_name" "$function_name" syntax description || {
			send_notice "$target" "Sorry, no help for ${format_bold}${command_name}${format_bold}"
			return
		}
		# And send it back to the user.
		if [[ $config_module_help_reply_in_one_line == 1 ]]; then
			send_notice "$target" "${format_bold}${command_name}${format_bold}$syntax -- $description"
		else
			send_notice "$target" "${format_bold}${command_name}${format_bold}$syntax"
			send_notice "$target" "$description"
		fi
	else
		local sendernick=
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "help" "<command>"
	fi
}

module_help_handler_modinfo() {
	local sender="$1"
	local parameters="$3"
	if [[ $parameters =~ ^([^ ]+) ]]; then
		local module_name="${BASH_REMATCH[1]}"
		# See module_help_handler_help
		local target
		if [[ $2 =~ ^# && $config_module_help_reply_in_channel == 1 ]]; then
			target="$2"
		else
			parse_hostmask_nick "$sender" 'target'
		fi
		local description=
		module_help_fetch_module_data "$module_name" description || {
			send_notice "$target" "Sorry, no information for module ${format_bold}${module_name}${format_bold}"
			return
		}
		if [[ $config_module_help_reply_in_one_line == 1 ]]; then
			send_notice "$target" "${format_bold}${module_name}${format_bold} -- $description"
		else
			send_notice "$target" "${format_bold}${module_name}${format_bold}"
			send_notice "$target" "$description"
		fi
	else
		local sendernick=
		parse_hostmask_nick "$sender" sendernick
		feedback_bad_syntax "$sendernick" "modinfo" "<module>"
	fi
}
