#!/bin/bash
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
## Access control library.
#---------------------------------------------------------------------


#---------------------------------------------------------------------
## Check for owner access.
## @Type API
## @param n!u@h mask
## @return 0 If access was granted
## @return 1 If access was denied.
#---------------------------------------------------------------------
access_check_owner() {
	security_assert_argc 1 1 "$@" || {
		log_error "Aiie! Access denied because of incorrect function call!"
		return 1
	}
	local index
	for index in ${!config_access_mask[*]}; do
		if [[ "$1" =~ ${config_access_mask[$index]} ]] && list_contains "config_access_capab[$index]" 'owner'; then
			return 0
		fi
	done
	return 1
}

#---------------------------------------------------------------------
## Check for access in scope.
## @Type API
## @param Capability to check for.
## @param n!u@h mask
## @param What scope
## @return 0 If access was granted
## @return 1 If access was denied.
#---------------------------------------------------------------------
access_check_capab() {
	security_assert_argc 3 3 "$@" || {
		log_error "Aiie! Access denied because of incorrect function call!"
		return 1
	}
	local index
	for index in ${!config_access_mask[*]}; do
		if [[ "$2" =~ ${config_access_mask[$index]} ]] && \
		   [[ "$3" =~ ${config_access_scope[$index]} ]]; then
			if list_contains "config_access_capab[$index]" "$1" || \
			   list_contains "config_access_capab[$index]" "owner"; then
				return 0
			fi
		fi
	done
	return 1
}

#---------------------------------------------------------------------
## Used to log actions like "did a rehash" if access was granted.
## @Type API
## @param n!u@h mask
## @param What happened.
#---------------------------------------------------------------------
access_log_action() {
	log_info_file owner.log "$1 performed the restricted action: $2"
}

#---------------------------------------------------------------------
## Return error message about failed access to someone, and log it
## @Type API
## @param n!u@h mask
## @param What they tried to do
## @param What capability they need
#---------------------------------------------------------------------
access_fail() {
	log_error_file access.log "$1 tried to \"$2\" but lacks access."
	local nick=
	parse_hostmask_nick "$sender" 'nick'
	send_msg "$nick" "Permission denied. You need the capability \"$3\" to do this action."
}
