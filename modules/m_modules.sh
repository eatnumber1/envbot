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
# Manage (load/unload/list) modules.

module_modules_INIT() {
	echo "on_PRIVMSG"
}

module_modules_UNLOAD() {
	unset module_modules_doload module_modules_dounload
	unset module_modules_on_PRIVMSG
}

module_modules_REHASH() {
	return 0
}

# $1 = Module to load
module_modules_doload() {
	local target_module="$1"
	modules_load "$target_module"
	local status_message status=$?
	case $status in
		0) status_message="Load successful" ;;
		2) status_message="Module \"$target_module\" is already loaded" ;;
		3) status_message="Failed to source it" ;;
		4) status_message="Module \"$target_module\" could not be found" ;;
		5) status_message="Getting hooks from module failed" ;;
		*) status_message="Unknown error (code $status)" ;;
	esac
	send_msg "$(parse_hostmask_nick "$sender")" "$status_message"
}

# $1 = Module to unload
module_modules_dounload() {
	local target_module="$1"
	if [[ $target_module == modules ]]; then
		send_msg "$(parse_hostmask_nick "$sender")" \
			"You can't reload the modules module using itself. The hackish way would be to use the eval module for this."
	fi
	modules_unload "$target_module"
	local status_message status=$?
	case $status in
		0) status_message="Unload successful" ;;
		2) status_message="Module \"$target_module\" is not loaded" ;;
		*) status_message="Unknown error (code $status)" ;;
	esac
	send_msg "$(parse_hostmask_nick "$sender")" "$status_message"
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_modules_on_PRIVMSG() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local channel="$2"
	local query="$3"
	local target_module
	local parameters
	if parameters="$(parse_query_is_command "$query" "modload")"; then
		if [[ "$parameters" =~ ^([^ ]+) ]]; then
			target_module="${BASH_REMATCH[1]}"
			if access_check_owner "$sender"; then
				module_modules_doload "$target_module"
			else
				access_fail "$sender" "load a module" "owner"
			fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "modload" "modulename"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "modunload")"; then
		if [[ "$parameters" =~ ^([^ ]+) ]]; then
			target_module="${BASH_REMATCH[1]}"
			if access_check_owner "$sender"; then
				module_modules_dounload "$target_module"
			else
				access_fail "$sender" "unload a module" "owner"
			fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "modunload" "modulename"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "modreload")"; then
		if [[ "$parameters" =~ ^([^ ]+) ]]; then
			target_module="${BASH_REMATCH[1]}"
			if access_check_owner "$sender"; then
				module_modules_dounload "$target_module"
				if [[ $? = 0 ]]; then
					module_modules_doload "$target_module"
				fi
			else
				access_fail "$sender" "unload a module" "owner"
			fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "modunload" "modulename"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "modlist")"; then
			if access_check_owner "$sender"; then
				local modlist
				for target_module in $modules_loaded; do
					modlist="$modlist $target_module"
				done
				send_msg "$(parse_hostmask_nick "$sender")" "Modules currently loaded:$modlist"
			else
				access_fail "$sender" "unload a module" "owner"
			fi
		return 1
	fi
	return 0
}
