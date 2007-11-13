#!/bin/bash
# -*- coding: UTF8 -*-
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
## Configuration management
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## Rehash config file.
## @Type API
## @return 0 Success.
## @return 2 Not same config version.
## @return 3 Failed to source. The bot should not be in an undefined state.
## @return 4 Failed to source. The bot may be in an undefined state.
#---------------------------------------------------------------------
config_rehash() {
	local new_conf_ver="$(grep -E '^config_version=' "$config_file")"
	if ! [[ $new_conf_ver =~ ^config_version=$config_current_version ]]; then
		log_error "REHASH: Not same config version"
		return 2
	fi
	# Try sourceing in a subshell first to catch errors
	# without causing bot to break
	( source "$config_file" )
	if [[ $? -ne 0 ]]; then
		log_error "REHASH: Failed faked source."
		return 3
	fi
	# Source for real if that worked
	source "$config_file"
	if [[ $? -ne 0 ]]; then
		log_error "REHASH: Failed real source."
		return 4
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
## Validate config file
## @Type Private
#---------------------------------------------------------------------
config_validate() {
	if [[ -z "$config_firstnick" ]]; then
		echo "ERROR: YOU MUST SET A config_firstnick IN THE CONFIG"
		envbot_quit 1
	fi
	if [[ -z "$config_log_dir" ]]; then
		echo "ERROR: YOU MUST SET A config_log_dir IN THE CONFIG"
		envbot_quit 1
	fi
	if [[ -z "$config_log_stdout" ]]; then
		echo "ERROR: YOU MUST SET config_log_stdout IN THE CONFIG"
		envbot_quit 1
	fi
	if [[ -z "${config_access_mask[1]}" ]]; then
		echo "ERROR: YOU MUST SET AT LEAST ONE OWNER IN EXAMPLE CONFIG"
		echo "       AND THAT OWNER MUST BE THE FIRST ONE (config_access_mask[1] that is)."
		envbot_quit 1
	fi
	if ! list_contains "config_access_capab[1]" "owner"; then
		echo "ERROR: YOU MUST SET AT LEAST ONE OWNER IN EXAMPLE CONFIG"
		echo "       AND THAT OWNER MUST BE THE FIRST ONE (config_access_capab[1] that is)."
		envbot_quit 1
	fi
	if [[ $config_server_ssl -ne 0 ]]; then
		if ! list_contains transport_supports "ssl"; then
			echo "ERROR: THIS TRANSPORT DOES NOT SUPORT SSL"
			envbot_quit 1
		fi
	else
		if ! list_contains transport_supports "nossl"; then
			echo "ERROR: THIS TRANSPORT REQUIRES SSL"
			envbot_quit 1
		fi
	fi
	if [[ "$config_server_bind" ]]; then
		if ! list_contains transport_supports "bind"; then
			echo "ERROR: THIS TRANSPORT DOES NOT SUPORT BINDING AN IP"
			envbot_quit 1
		fi
	fi
	if ! [[ -d "$config_modules_dir" ]]; then
		if ! list_contains transport_supports "bind"; then
			echo "ERROR: $config_modules_dir DOES NOT EXIST OR IS NOT A DIRECTORY."
			envbot_quit 1
		fi
	fi
}
