#!/bin/bash
# -*- coding: UTF8 -*-
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
## Functions for working with time.
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## Check if a set time has passed
## @Type API
## @param Unix timestamp to check against
## @param Number of seconds
## @return 0 If at least the given number of seconds has passed
## @return 1 If it hasn't
#---------------------------------------------------------------------
time_check_interval() {
	local newtime=
	time_get_current 'newtime'
	(( ( newtime - $1 ) > $2 ))
}


#---------------------------------------------------------------------
## Get current time (seconds since 1970-01-01 00:00:00 UTC)
## @Type API
## @param Variable to return current timestamp in
#---------------------------------------------------------------------
time_get_current() {
	printf -v "$1" '%s' "$(( time_initial + SECONDS ))"
}


#---------------------------------------------------------------------
## Returns how long a time interval is in a human readable format.
## @Type API
## @param Time interval
## @param Variable to return new list in.
## @Note Modified version of function posted by goedel at
## @Note http://forum.bash-hackers.org/index.php?topic=59.0
#---------------------------------------------------------------------
time_format_difference() {
	local tdiv=$1
	local tmod i
	local output=""

	for ((i=0; i < ${#time_format_units[@]}; ++i)); do
		# n means no limit.
		if [[ ${time_format_unitspan[i]} == n ]]; then
			tmod=$tdiv
		else
			(( tmod = tdiv % time_format_unitspan[i] ))
			(( tdiv = tdiv / time_format_unitspan[i] ))
		fi
		output="$tmod${time_format_units[i]} $output"
		[[ $tdiv = 0 ]] && break
	done

	printf -v "$2" '%s' "${output% }"
}

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

#---------------------------------------------------------------------
## Array used for time_format_difference
## @Type Private
#---------------------------------------------------------------------
time_format_units=( s min h d mon )
#---------------------------------------------------------------------
## Array used for time_format_difference
## @Type Private
## @Note n means no limit.
#---------------------------------------------------------------------
time_format_unitspan=( 60 60 24 30 n )

#---------------------------------------------------------------------
## Initial timestamp that we use to get current time later on.
## @Type Private
#---------------------------------------------------------------------
time_initial=''

#---------------------------------------------------------------------
## Set up time variables
## @Type Private
#---------------------------------------------------------------------
time_init() {
	# Set up initial env
	time_initial="$(date -u +%s)"
	SECONDS=0
}
