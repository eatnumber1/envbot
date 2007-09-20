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

# Quits the bot in a graceful way:
# Optional parameters:
# $1 = Reason to quit
# $2 = Return status (if not given, then exit 0).
quit_bot() {
	for module in $modules_before_disconnect; do
		module_${module}_before_disconnect
	done
	local reason=$1
	send_quit "$reason"
	connected=0
	for module in $modules_after_disconnect; do
		module_${module}_after_disconnect
	done
	for module in $modules_FINALISE; do
		${module}_FINALISE
	done
	log "Bot quit gracefully"
	transport_disconnect
	if [[ $2 ]]; then
		exit $2
	else
		exit 0
	fi
}

# Remove a value from a space separated list
# $1 = List to remove from
# $2 = Value to remove
# Returns new list on STDOUT
list_remove() {
	local oldlist="${!1}"
	local newlist=${oldlist//$2}
	echo "$(sed 's/^ \+//;s/ \+$//;s/ \{2,\}/ /g' <<< "$newlist")" # Get rid of the unneeded spaces.
}

# Checks if a space separated list contains a value
# $1 = List to check
# $2 = Value to check for
# Returns 0 if found, otherwise 1.
list_contains() {
	grep -wq "$2" <<< "${!1}"
}

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################
validate_config() {
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
