#!/bin/bash
###########################################################################
#                                                                         #
#   Copyright (c)                                                         #
#     Arvid Norlander <anmaster@kuonet.org>                               #
#     EmErgE <halt.system@gmail.com>                                      #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
###########################################################################
# Load/unload modules.

module_load_INIT() {
	echo "on_PRIVMSG"
}

module_load_UNLOAD() {
	unset module_load_on_PRIVMSG
}

module_load_REHASH() {
	return 0
}


# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_load_on_PRIVMSG() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local channel="$2"
	local query="$3"
	local target_module status_message status
	local parameters
	if parameters="$(parse_query_is_command "$query" "modload")"; then
		if [[ "$parameters" =~ ^([^ ]+) ]]; then
			target_module="${BASH_REMATCH[1]}"
			if access_check_owner "$sender"; then
				modules_load "$target_module"
				status=$?
				case $status in
					0) status_message="Load successful" ;;
					2) status_message="Module \"$target_module\" is already loaded" ;;
					3) status_message="Failed to source it" ;;
					4) status_message="Module \"$target_module\" could not be found" ;;
					5) status_message="Getting hooks from module failed" ;;
					*) status_message="Unknown error (code $status)" ;;
				esac
				send_msg "$(parse_hostmask_nick "$sender")" "$status_message"
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
				modules_unload "$target_module"
				status=$?
				case $status in
					0) status_message="Unload successful" ;;
					2) status_message="Module \"$target_module\" is not loaded" ;;
					*) status_message="Unknown error (code $status)" ;;
				esac
				send_msg "$(parse_hostmask_nick "$sender")" "$status_message"
			else
				access_fail "$sender" "unload a module" "owner"
			fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "modunload" "modulename"
		fi
		return 1
	fi

	return 0
}
