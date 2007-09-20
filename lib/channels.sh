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

# Space separated list of current channels
channels_current=""

# Join a channel
# $1 the channel to join
# $2 is a channel key, if any.
channels_join() {
	local channel="$1"
	local key=""
	[[ -n "$2" ]] && key=" $2"
	send_raw "JOIN ${channel}${key}"
}

# Part a channel
# $1 the channel to part
# $2 is a reason.
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

# Internal function
# Adds channels to the list
channels_add() {
	channels_current="$channels_current $1"
}

# Internal function
# Removes channels to the list
channels_remove() {
	channels_current="$(list_remove channels_current $1)"
}

# Check if we parted
channels_handle_part() {
	local whoparted="$(parse_hostmask_nick "$1")"
	if [[ $whoparted == $nick_current ]]; then
		channels_remove "$2"
	fi
}

# Check if we got kicked
channels_handle_kick() {
	local whogotkicked="$3"
	if [[ $whogotkicked == $nick_current ]]; then
		channels_remove "$2"
	fi
}

# Check if we joined
channels_handle_join() {
	local whojoined="$(parse_hostmask_nick "$1")"
	if [[ $whojoined == $nick_current ]]; then
		channels_add "$2"
	fi
}
