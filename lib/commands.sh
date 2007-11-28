#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
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
#---------------------------------------------------------------------
## Handle registering of commands
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## List of commands (maps to function for the command), a hash
## @Note Dummy variable to document the fact that it is a hash.
## @Type Private
#---------------------------------------------------------------------
commands_list=''

#---------------------------------------------------------------------
## List of functions (by module), a hash
## @Note Dummy variable to document the fact that it is a hash.
## @Type Private
#---------------------------------------------------------------------
commands_modules_functions=''

#---------------------------------------------------------------------
## List of commands (by function), a hash
## @Note Dummy variable to document the fact that it is a hash.
## @Type Private
#---------------------------------------------------------------------
commands_function_commands=''

#---------------------------------------------------------------------
## List of commands (by module)
## @Note Dummy variable to document the fact that it is a hash.
## @Type Private
#---------------------------------------------------------------------
commands_module_commands=''

#---------------------------------------------------------------------
## List of modules (by command)
## @Note Dummy variable to document the fact that it is a hash.
## @Type Private
#---------------------------------------------------------------------
commands_commands_module=''

#---------------------------------------------------------------------
## Comma separated list of all commands
## @Type Semi-private
#---------------------------------------------------------------------
commands_commands=''

# Just unset dummy variables.
unset commands_list commands_modules_functions commands_function_commands commands_module_commands commands_module_commands

#---------------------------------------------------------------------
## Register a command.
## @Type API
## @param Module name
## @param Function name (Part after module_modulename_handler_)
## @param Command name (on IRC, may contain spaces) (optional, defaults to same as function name, that is $2)
## @return 0 If successful
## @return 1 If failed for other reason
## @return 2 If invalid command name
## @return 3 If the command already exists (maybe from some other module)
## @return 4 If the function already exists for other command.
## @return 5 If the function in question is not declared.
#---------------------------------------------------------------------
commands_register() {
	# Speed isn't that important here, it is only called at module load after all.
	local module="$1"
	local function_name="$2"
	local command_name="$3"
	# Command name is optional
	if [[ -z $command_name ]]; then
		command_name="$function_name"
	fi
	# Check for valid command name
	if ! [[ $command_name =~ ^[a-zA-Z0-9] ]]; then
		log_error "commands_register_command: Module \"$module\" gave invalid command name \"$command_name\". First char of command must be alphanumeric."
		return 2
	fi
	if ! [[ $command_name =~ ^[a-zA-Z0-9][^\ ,]*( [^, ]+)?$ ]]; then
		log_error "commands_register_command: Module \"$module\" gave invalid command name \"$command_name\". A command can be at most 2 words and should have no trailing white space and may not contain a \",\" (comma)."
		return 2
	fi
	# Bail out if command is already registered.
	if hash_exists 'commands_list' "$command_name"; then
		log_error "commands_register_command: Failed to register command from \"$module\": a command with the name \"$command_name\" already exists."
		return 3
	fi
	# Bail out if the function already is mapped to some other command
	if hash_exists 'commands_function_commands' "$function_name"; then
		log_error "commands_register_command: Failed to register command from \"$module\": the function is already registered under another command name."
		return 4
	fi

	# Does the function itself exist?
	local full_function_name="module_${module}_handler_${function_name}"
	if ! declare -F | grep -qe "^declare -f ${full_function_name}$"; then
		log_error "commands_register_command: Failed to register command from \"$module\": the function $full_function_name does not exist"
		return 5
	fi
	# So it was valid. Lets add it then.

	# Store in module -> function mapping.
	hash_append 'commands_modules_functions' "$module" "$function_name" || {
		log_error "commands_register_command: module -> commands mapping failed: mod=\"$module\" func=\"$function_name\"."
		return 1
	}
	# Store in command -> function mapping
	hash_set 'commands_list' "$command_name" "$full_function_name" || {
		log_error "commands_register_command: command -> function mapping failed: cmd=\"$command_name\" full_func=\"$full_function_name\"."
		return 1
	}
	# Store in function -> command mapping
	hash_set 'commands_function_commands' "$function_name" "$command_name" || {
		log_error "commands_register_command: function -> command mapping failed: func=\"$function_name\" cmd=\"$command_name\"."
		return 1
	}
	# Store in command -> module mapping
	hash_set 'commands_commands_module' "$command_name" "$module" || {
		log_error "commands_register_command: command -> module mapping failed: cmd=\"$command_name\" mod=\"$module\"."
		return 1
	}
	# Store in module -> commands mapping (ick!)
	hash_append 'commands_module_commands' "$module" "$command_name" ',' || {
		log_error "commands_register_command: module -> command mapping failed: mod=\"$module\" cmd=\"$command_name\"."
	}
	# Store in comma-separated command list
	if [[ $commands_commands ]]; then
		commands_commands+=",$command_name" || return 1
	else
		commands_commands="$command_name" || return 1
	fi
}

#---------------------------------------------------------------------
## Get what module provides a command.
## @param Command to find.
## @param Variable to return in
## @Type Semi-private
#---------------------------------------------------------------------
commands_provides() {
	hash_get "commands_commands_module" "$1" "$2"
}

#---------------------------------------------------------------------
## Get what commands exist in a module.
## @param Command to find.
## @param Variable to return comma separated list in
## @Type Semi-private
#---------------------------------------------------------------------
commands_in_module() {
	hash_get "commands_module_commands" "$1" "$2"
}

#---------------------------------------------------------------------
## Will remove all commands from a module and unset the functions in question.
## @Type Private
## @param Module
## @return 0 If successful (or no commands exist for module)
## @return 1 If error
## @return 2 If fatal error
#---------------------------------------------------------------------
commands_unregister() {
	local module="$1"
	# Are there any commands?
	hash_exists 'commands_modules_functions' "$module" || {
		return 0
	}
	local function_name full_function_name command_name functions
	# Get list of functions
	hash_get 'commands_modules_functions' "$module" 'functions' || return 2
	# Iterate through the functions
	for function_name in $functions; do
		# Get command name
		hash_get 'commands_function_commands' "$function_name" 'command_name' || return 2
		# Unset from function -> command hash
		hash_unset 'commands_function_commands' "$function_name" || return 2
		# Unset from command -> function hash
		hash_unset 'commands_list' "$command_name" || return 2
		# Unset from command -> module mapping
		hash_unset 'commands_commands_module' "$command_name" || return 2
		# Remove from command list.
		list_remove 'commands_commands' "$command_name" 'commands_commands' "," || return 1
		# Unset function itself.
		full_function_name="module_${module}_handler_${function_name}"
		unset "$full_function_name" || return 2
	done
	# Unset the module -> commands mapping.
	hash_unset 'commands_module_commands' "$module" || return 2
	# Finally unset module -> functions mapping.
	hash_unset 'commands_modules_functions' "$module" || return 2
}

#---------------------------------------------------------------------
## Process a line finding what command it would be
## @Type Private
## @param Sender
## @param Target
## @param Query
## @return 0 If not a command
## @return 1 If it indeed was a command that we therefore handled.
## @return 2 A command but that didn't exist.
#---------------------------------------------------------------------
commands_call_command() {
	local regex="${config_commands_listenregex}"
	# Not on a channel?
	if [[ ! $2 =~ ^# ]]; then
		# Should we treat it as a command anyway?
		if [[ $config_commands_private_always == 1 ]]; then
			local regex="(${config_commands_listenregex})?"
		fi
	fi
	# Check if it is a command.
	# (${config_commands_listenregex}, followed by an alphanumeric char.)
	if [[ "$3" =~ ^${regex}([a-zA-Z0-9].*) ]]; then
		local data="${BASH_REMATCH[@]: -1}"
		# Right, get the parts of the command
		if [[ $data =~ ^([a-zA-Z0-9][^ ]*)( [^, ]+)?( .*)? ]]; then
			local firstword="${BASH_REMATCH[1]}"
			local secondword="${BASH_REMATCH[2]}"
			local parameters="${BASH_REMATCH[3]}"

			local function=
			# Check for two word commands first.
			hash_get 'commands_list' "${firstword}${secondword}" 'function'
			if [[ -z "$function" ]]; then
				# Maybe one word then?
				hash_get 'commands_list' "$firstword" 'function'
				if [[ "$function" ]]; then
					parameters="${secondword}${parameters}"
				# No, not that either
				else
					return 2
				fi
			fi

			# So we got a command, now lets run it
			# (strip leading white spaces) from parameters.
			"$function" "$1" "$2" "${parameters## }"
			return 1
		fi
		return 2
	fi
	return 0
}
