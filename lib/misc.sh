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

# Quits the bot in a graceful way.
# Parameters
#   $1 Reason to quit (optional)
#   $2 Return status (optional, if not given, then exit 0).
bot_quit() {
	for module in $modules_before_disconnect; do
		module_${module}_before_disconnect
	done
	local reason=$1
	send_quit "$reason"
	server_connected=0
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

# Restart the bot in a graceful way. I hope.
# Parameters
#   $1 Reason to restart (optional)
bot_restart() {
	for module in $modules_before_disconnect; do
		module_${module}_before_disconnect
	done
	local reason=$1
	send_quit "$reason"
	server_connected=0
	for module in $modules_after_disconnect; do
		module_${module}_after_disconnect
	done
	for module in $modules_FINALISE; do
		${module}_FINALISE
	done
	log "Bot quit gracefully"
	transport_disconnect
	exec env -i "$(type -p bash)" $0 $command_line
}

# Remove a value from a space separated list.
# Parameters
#   $1 List to remove from.
#   $2 Value to remove.
# Returns
#   New list on STDOUT.
list_remove() {
	local oldlist="${!1}"
	local newlist=${oldlist//$2}
	echo "$(sed 's/^ \+//;s/ \+$//;s/ \{2,\}/ /g' <<< "$newlist")" # Get rid of the unneeded spaces.
}

# Checks if a space separated list contains a value.
# Parameters
#   $1 List to check.
#   $2 Value to check for.
# Return code
#   0 If found.
#   1 If not found.
list_contains() {
	grep -wq "$2" <<< "${!1}"
}
