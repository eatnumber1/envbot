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

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

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
