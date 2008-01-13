#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2008  Arvid Norlander                               #
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
## Data parsing
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## Get parts of hostmask.
## @Note In most cases you should use one of
## @Note <@function parse_hostmask_nick>, <@function parse_hostmask_ident>
## @Note or <@function parse_hostmask_host>. Only use this function
## @Note if you want all several parts.
## @Type API
## @param n!u@h mask
## @param Variable to return nick in
## @param Variable to return ident in
## @param Variable to return host in
#---------------------------------------------------------------------
parse_hostmask() {
	if [[ $1 =~ ^([^ !]+)!([^ @]+)@([^ ]+) ]]; then
		printf -v "$2" '%s' "${BASH_REMATCH[1]}"
		printf -v "$3" '%s' "${BASH_REMATCH[2]}"
		printf -v "$4" '%s' "${BASH_REMATCH[3]}"
	fi
}

#---------------------------------------------------------------------
## Get nick from hostmask
## @Type API
## @param n!u@h mask
## @param Variable to return result in
#---------------------------------------------------------------------
parse_hostmask_nick() {
	if [[ $1 =~ ^([^ !]+)! ]]; then
		printf -v "$2" '%s' "${BASH_REMATCH[1]}"
	fi
}

#---------------------------------------------------------------------
## Get ident from hostmask
## @Type API
## @param n!u@h mask
## @param Variable to return result in
#---------------------------------------------------------------------
parse_hostmask_ident() {
	if [[ $1 =~ ^[^\ !]+!([^ @]+)@ ]]; then
		printf -v "$2" '%s' "${BASH_REMATCH[1]}"
	fi
}

#---------------------------------------------------------------------
## Get host from hostmask
## @Type API
## @param n!u@h mask
## @param Variable to return result in
#---------------------------------------------------------------------
parse_hostmask_host() {
	if [[ $1 =~ ^[^\ !]+![^\ @]+@([^ ]+) ]]; then
		printf -v "$2" '%s' "${BASH_REMATCH[1]}"
	fi
}

#---------------------------------------------------------------------
## This is used to get data out of 005.
## @Type API
## @param Name of data to get
## @param Variable to return result (if any result) in
## @return 0 If found otherwise 1
## @Note That if the variable doesn't have any data,
## @Note but still exist it will return nothing on STDOUT
## @Note but 0 as error code
#---------------------------------------------------------------------
parse_005() {
	if [[ $server_005 =~ ${1}(=([^ ]+))? ]]; then
		if [[ ${BASH_REMATCH[2]} ]]; then
			printf -v "$2" '%s' "${BASH_REMATCH[2]}"
		fi
		return 0
	fi
	return 1
}
