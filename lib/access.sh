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

# Check for owner access.
# Parameters
#   $1 n!u@h mask
# Return status
#   0 On owner
#   1 Otherwise
access_check_owner() {
	local owner
	for owner in "${config_owners[@]}"; do
		if [[ "$1" =~ $owner ]]; then
			return 0
		fi
	done
	return 1
}

# Return error, and log it
# Parameters
#   $1 n!u@h
#   $2 What they tried to do
#   $3 What access they need
access_fail() {
	log_stdout_file access.log "$1 tried to \"$2\" but lacks access."
	send_msg "$(parse_hostmask_nick $sender)" "Permission denied. You need $3 access for this."
}
