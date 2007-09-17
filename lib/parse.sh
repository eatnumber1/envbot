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

# Bad name of function, it gets the argument
# after a ":", the last multiword argument
# Only reads FIRST as data
# Returns on STDOUT
# FIXME: Can't handle a ":" in a word before the place to split
parse_get_colon_arg() {
	cut -d':' -f2- <<< "$1"
}

# Get nick from hostmask
# Returns on STDOUT: nick
# parameter: n!u@h mask
parse_hostmask_nick() {
	cut -d'!' -f1 <<< "$1"
}
# Get ident from hostmask
# Returns on STDOUT: nick
# parameter: n!u@h mask
parse_hostmask_ident() {
	cut -d'!' -f2 <<< "$1" | cut -d'@' -f1
}
# Get host from hostmask
# Returns on STDOUT: nick
# parameter: n!u@h mask
parse_hostmask_host() {
	cut -d'@' -f2 <<< "$1"
}

# This is used to get data out of 005.
# $1 = Name of data to get
# Returns 0 if found, otherwise 1.
# Returns on STDOUT the variable data in question, if any
#         Note that if the variable doesn't have any data,
#         but still exist it will return nothing on STDOUT
#         but 0 as error code
parse_005() {
	if [[ $server_005 =~ ${1}(=([^ ]+))? ]]; then
		# Some, but not all also send what char the modes for INVEX is.
		# If it isn't sent, guess one +I
		if [[ ${BASH_REMATCH[2]} ]]; then
			echo -n "${BASH_REMATCH[2]}"
		fi
		return 0
	fi
	return 1
}

# $1 = The query to check, this should be the part
#      after the : in PRIVMSG.
# $2 = What command to look for.
# Return: 0 = Matches
#         1 = Doesn't match
# Returned on STDOUT if matches: The parameters
parse_query_is_command() {
	if [[ "$1" =~ ^${config_listenregex}${2}(\ (.*)|$) ]]; then
		echo "${BASH_REMATCH[@]: -1}"
		return 0
	else
		return 1
	fi
}
