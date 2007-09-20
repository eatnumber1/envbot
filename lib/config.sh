#!/bin/bash
###########################################################################
#                                                                         #
#  envbot - an irc bot in bash                                            #
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

# Return status:
# 0 = Sucess
# 1 = Other error
# 2 = Not same config version
# 3 = Failed to source. The bot should not be in an undefined state
# 4 = Failed to source. The bot may be in an undefined state
config_rehash() {
	local new_conf_ver="$(grep -E '^config_version=' "$config_file")"
	if ! [[ $new_conf_ver =~ ^config_version=$config_current_version ]]; then
		log_stdout "REHASH: Not same config version"
		return 2
	fi
	# Try sourcing in a subshell first to catch errors
	# without causing bot to break
	( source "$config_file" )
	if [[ $? -ne 0 ]]; then
		log_stdout "REHASH: Failed faked source."
		return 3
	fi
	# Source for real if that worked
	source "$config_file"
	if [[ $? -ne 0 ]]; then
		log_stdout "REHASH: Failed real source."
		return 4
	fi
	local status
	for module in $modules_loaded; do
		module_${module}_REHASH
		status=$?
		if [[ $status -eq 1 ]]; then
			log_stdout "ERROR: Rehash of ${module} failed, trying to unload it."
			modules_unload "${module}" || {
				log_stdout "FATAL ERROR: Unloading of ${module} after failed rehash failed."
				quit_bot "Fatal error in unload of module that failed to rehash"
			}
		fi
		if [[ $status -eq 2 ]]; then
			log_stdout "FATAL ERROR: Rehash of ${module} failed in a FATAL way. Quitting"
			quit_bot "Fatal error in rehash of module"
		fi
	done
	log_stdout "Rehash successfull"
}


###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################
config_validate() {
	if [ -z "$config_version" ]; then
		echo "ERROR: YOU MUST SET THE CORRECT config_version IN THE CONFIG"
		exit 1
	fi
	if [ $config_version -ne $config_current_version ]; then
		echo "ERROR: YOUR config_version IS $config_version BUT THE BOT'S CONFIG VERSION IS $config_current_version."
		echo "PLEASE UPDATE YOUR CONFIG. Check bot_settings.sh.example for current format."
		exit 1
	fi
	if [ -z "$config_firstnick" ]; then
		echo "ERROR: YOU MUST SET A config_firstnick IN THE CONFIG"
		exit 1
	fi
	if [ -z "$config_log_dir" ]; then
		echo "ERROR: YOU MUST SET A config_log_dir IN THE CONFIG"
		exit 1
	fi
	if [ -z "$config_log_stdout" ]; then
		echo "ERROR: YOU MUST SET config_log_stdout IN THE CONFIG"
		exit 1
	fi
	if [ -z "${config_owners[1]}" ]; then
		echo "ERROR: YOU MUST SET AT LEAST ONE OWNER IN EXAMPLE CONFIG"
		echo "       AND THAT OWNER MUST BE THE FIRST ONE (config_owners[1] that is)."
		exit 1
	fi
	if [[ $config_server_ssl -ne 0 ]]; then
		if ! list_contains transport_supports "ssl"; then
			echo "ERROR: THIS TRANSPORT DOES NOT SUPORT SSL"
			exit 1
		fi
	else
		if ! list_contains transport_supports "nossl"; then
			echo "ERROR: THIS TRANSPORT REQUIRES SSL"
			exit 1
		fi
	fi
	if [[ "$config_server_bind" ]]; then
		if ! list_contains transport_supports "bind"; then
			echo "ERROR: THIS TRANSPORT DOES NOT SUPORT BINDING AN IP"
			exit 1
		fi
	fi
}
