#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2008  Arvid Norlander                               #
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
## Configuration management
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## Rehash config file.
## @Type API
## @return 0 Success.
## @return 2 Not same config version.
## @return 3 Failed to source. The bot should not be in an undefined state.
## @return 4 Config validation on faked source failed. The bot should not be in an undefined state.
## @return 5 Failed to source. The bot may be in an undefined state.
## @Note If config validation fails at REAL source, the bot may quit. However this should never happen.
#---------------------------------------------------------------------
config_rehash() {
	local new_conf_ver="$(grep -E '^config_version=' "$config_file")"
	if ! [[ $new_conf_ver =~ ^config_version=$config_current_version ]]; then
		log_error "REHASH: Not same config version. Rehash aborted."
		return 2
	fi
	# Try sourceing in a subshell first to catch errors
	# without causing bot to break
	( source "$config_file" )
	if [[ $? -ne 0 ]]; then
		log_error "REHASH: Failed faked source. Rehash aborted. (TIP: Check for syntax errors in config and any message above this message.)"
		return 3
	fi
	# HACK: Subshell, then unset all but two config_ variables (one is readonly, the other is needed to validate)
	# Then source config file and run validation on it.
	( unset -v $(sed 's/ *config_current_version */ /g;s/ *config_file */ /g' <<<"${!config_*}")
		source "$config_file"
		config_validate && config_validate_transport )
	if [[ $? -ne 0 ]]; then
		log_error "REHASH: Failed config validation on new config. Rehash aborted."
		return 4
	fi
	# Source for real if that worked
	source "$config_file"
	if [[ $? -ne 0 ]]; then
		log_error "REHASH: Failed real source. BOT MAY BE IN UNDEFINED STATE."
		return 5
	fi
	# Lets force command line -v, it may have been overwritten by config.
	if [[ $force_verbose -eq 1 ]]; then
		config_log_stdout='1'
	fi
	local status
	modules_load_from_config
	for module in $modules_loaded; do
		module_${module}_REHASH
		status=$?
		if [[ $status -eq 1 ]]; then
			log_error "Rehash of ${module} failed, trying to unload it."
			modules_unload "${module}" || {
				log_fatal "Unloading of ${module} after failed rehash failed."
				bot_quit "Fatal error in unload of module that failed to rehash"
			}
		fi
		if [[ $status -eq 2 ]]; then
			log_fatal "Rehash of ${module} failed in a FATAL way. Quitting"
			bot_quit "Fatal error in rehash of module"
		fi
	done
	log_info_stdout "Rehash successful"
}


###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

#---------------------------------------------------------------------
## This will call logging if logging is setup,
## otherwise just print to STDOUT, with prefix
## @Type Private
#---------------------------------------------------------------------
config_dolog_fatal() {
	if [[ $log_file ]]; then
		log_fatal "$1"
	else
		echo "FATAL ERROR: $1"
	fi
}

#---------------------------------------------------------------------
## Returns an error if the variable in question is empty/not set
## @Note Works only for non-array variables
## @Type Private
## @param Variable name
## @param Extra error line(s) to append (optional, one parameter for each extra line)
#---------------------------------------------------------------------
config_validate_check_exists() {
	if [[ -z "${!1}" ]]; then
		config_dolog_fatal "YOU MUST SET $1 IN THE CONFIG"
		shift
		# Do the rest of the messages
		local line=
		for line in "$@"; do
			config_dolog_fatal "$line"
		done
		envbot_quit 2
	fi
}


#---------------------------------------------------------------------
## Validate config file
## @Type Private
#---------------------------------------------------------------------
config_validate() {
	# Note: normal logging is not initialized yet at this point,
	# so we use config_dolog_fatal, that calls normal logging in case
	# logging is loaded (like rehash).

	# General settings
	config_validate_check_exists config_firstnick
	config_validate_check_exists config_ident
	config_validate_check_exists config_gecos

	# Server settings
	config_validate_check_exists config_server
	config_validate_check_exists config_server_port
	config_validate_check_exists config_server_ssl

	# Logging
	config_validate_check_exists config_log_dir
	config_validate_check_exists config_log_stdout
	config_validate_check_exists config_log_raw
	config_validate_check_exists config_log_colors

	# Commands
	config_validate_check_exists config_commands_listenregex
	config_validate_check_exists config_commands_private_always

	# Feedback
	config_validate_check_exists config_feedback_unknown_commands

	# Access
	if [[ -z "${config_access_mask[1]}" ]]; then
		config_dolog_fatal "YOU MUST SET AT LEAST ONE OWNER IN EXAMPLE CONFIG"
		config_dolog_fatal "AND THAT OWNER MUST BE THE FIRST ONE (config_access_mask[1] that is)."
		envbot_quit 1
	fi
	if ! list_contains "config_access_capab[1]" "owner"; then
		config_dolog_fatal "YOU MUST SET AT LEAST ONE OWNER IN EXAMPLE CONFIG"
		config_dolog_fatal "AND THAT OWNER MUST BE THE FIRST ONE (config_access_capab[1] that is)."
		envbot_quit 1
	fi

	# Transports
	config_validate_check_exists "config_transport_dir"
	if [[ ! -d "${config_transport_dir}" ]]; then
		config_dolog_fatal "The transport directory ${config_transport_dir} doesn't seem to exist"
		envbot_quit 2
	fi
	config_validate_check_exists "config_transport"
	if [[ ! -r "${config_transport_dir}/${config_transport}.sh" ]]; then
		config_dolog_fatal "The transport ${config_transport} doesn't seem to exist"
		envbot_quit 2
	fi

	# Modules
	config_validate_check_exists config_modules_dir
	if ! [[ -d "$config_modules_dir" ]]; then
		if ! list_contains transport_supports "bind"; then
			config_dolog_fatal "$config_modules_dir DOES NOT EXIST OR IS NOT A DIRECTORY."
			envbot_quit 1
		fi
	fi
	config_validate_check_exists config_modules
}

#---------------------------------------------------------------------
## Validate some settings from config file that can only be done after
## transport was loaded.
## @Type Private
#---------------------------------------------------------------------
config_validate_transport() {
	# At this point logging is enabled, we can use it.
	if [[ $config_server_ssl -ne 0 ]]; then
		if ! list_contains transport_supports "ssl"; then
			log_fatal "THIS TRANSPORT DOES NOT SUPORT SSL"
			envbot_quit 1
		fi
	else
		if ! list_contains transport_supports "nossl"; then
			log_fatal "THIS TRANSPORT REQUIRES SSL"
			envbot_quit 1
		fi
	fi
	if [[ "$config_server_bind" ]]; then
		if ! list_contains transport_supports "bind"; then
			log_fatal "THIS TRANSPORT DOES NOT SUPORT BINDING AN IP"
			envbot_quit 1
		fi
	fi
}
