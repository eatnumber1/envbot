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

# Get nick from hostmask
# Parameters
#   $1 n!u@h mask
# Returns on STDOUT
#   Nick
parse_hostmask_nick() {
	if [[ $1 =~ ^([^ !]+)! ]]; then
		echo "${BASH_REMATCH[1]}"
	fi
}
# Get ident from hostmask
# Parameters
#   $1 n!u@h mask
# Returns on STDOUT
#   Ident
parse_hostmask_ident() {
	if [[ $1 =~ ^[^\ !]+!([^ @]+)@ ]]; then
		echo "${BASH_REMATCH[1]}"
	fi
}
# Get host from hostmask
# Parameters
#   $1 n!u@h mask
# Returns on STDOUT
#   Host
parse_hostmask_host() {
	if [[ $1 =~ ^[^\ !]+![^\ @]+@([^ ]+) ]]; then
		echo "${BASH_REMATCH[1]}"
	fi
}

# This is used to get data out of 005.
# Parameters
#   $1 Name of data to get
# Return status
#   0 If found
#   1 If not found
# Returns on STDOUT
#   The variable data in question, if any
# Note
#   That if the variable doesn't have any data,
#   but still exist it will return nothing on STDOUT
#   but 0 as error code
parse_005() {
	if [[ $server_005 =~ ${1}(=([^ ]+))? ]]; then
		if [[ ${BASH_REMATCH[2]} ]]; then
			echo -n "${BASH_REMATCH[2]}"
		fi
		return 0
	fi
	return 1
}

# Check if a query matches a command. If it matches extract the
# parameters.
# Parameters
#   $1 The query to check, this should be the part after the : in PRIVMSG.
#   $2 What command to look for.
# Return status
#   0 Matches
#   1 Doesn't match
# Returns on STDOUT
#   If matches: The parameters (if any)
parse_query_is_command() {
	if [[ "$1" =~ ^${config_listenregex}${2}(\ (.*)|$) ]]; then
		echo "${BASH_REMATCH[@]: -1}"
		return 0
	else
		return 1
	fi
}
