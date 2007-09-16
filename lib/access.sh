#!/bin/bash
###########################################################################
#                                                                         #
#   Copyright (c)                                                         #
#     Arvid Norlander <anmaster@kuonet.org>                               #
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

# Check for owner access.
# Returns 0 on owner
#         1 otherwise
# parameter: n!u@h mask
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
# $1  n!u@h
# $2 what they tried to do
# $3 what access they need
access_fail() {
	log "$1 tried to \"$2\" but lacks access"
	send_msg "$(parse_hostmask_nick $sender)" "Permission denied. You need $3 access for this."
	sleep 1
}
