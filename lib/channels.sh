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
## Channel management.
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## Space separated list of current channels
## @Type API
#---------------------------------------------------------------------
channels_current=""

#---------------------------------------------------------------------
## Join a channel
## @Type API
## @param The channel to join.
## @param Is a channel key, if any.
#---------------------------------------------------------------------
channels_join() {
	local channel="$1"
	local key=""
	[[ -n "$2" ]] && key=" $2"
	send_raw "JOIN ${channel}${key}"
}

#---------------------------------------------------------------------
## Part a channel
## @Type API
## @param The channel to part
## @param Is a reason.
#---------------------------------------------------------------------
channels_part() {
	local channel="$1"
	local reason=""
	[[ -n "$2" ]] && reason=" :$2"
	send_raw "PART ${channel}${reason}"
}

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

#---------------------------------------------------------------------
## Internal function!
## Adds channels to the list
## @Type Private
## @param The channel to add
#---------------------------------------------------------------------
channels_add() {
	channels_current="$channels_current $1"
}

#---------------------------------------------------------------------
## Internal function!
## Removes channels to the list
## @Type Private
## @param The channel to remove
#---------------------------------------------------------------------
channels_remove() {
	list_remove channels_current "$1" channels_current
}

#---------------------------------------------------------------------
## Check if we parted, called from main loop
## @Type Private
## @param n!u@h mask
## @param Channel parted.
## @param Reason (ignored).
#---------------------------------------------------------------------
channels_handle_part() {
	local whoparted=
	parse_hostmask_nick "$1" 'whoparted'
	if [[ $whoparted == $server_nick_current ]]; then
		channels_remove "$2"
	fi
}

#---------------------------------------------------------------------
## Check if we got kicked, called from main loop
## @Type Private
## @param n!u@h mask of kicker
## @param Channel kicked from.
## @param Nick of kicked user
## @param Reason (ignored).
#---------------------------------------------------------------------
channels_handle_kick() {
	local whogotkicked="$3"
	if [[ $whogotkicked == $server_nick_current ]]; then
		channels_remove "$2"
	fi
}

#---------------------------------------------------------------------
## Check if we joined, called from main loop
## @Type Private
## @param n!u@h mask
## @param Channel joined.
#---------------------------------------------------------------------
channels_handle_join() {
	local whojoined=
	parse_hostmask_nick "$1" 'whojoined'
	if [[ $whojoined == $server_nick_current ]]; then
		channels_add "$2"
	fi
}
