#!/bin/bash
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007  EmErgE <halt.system@gmail.com>                     #
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
## Calculate with bc
#---------------------------------------------------------------------

module_calc_INIT() {
	echo 'on_PRIVMSG'
}

module_calc_UNLOAD() {
	return 0
}

module_calc_REHASH() {
	return 0
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_calc_on_PRIVMSG() {
	local sender="$1"
	local channel="$2"
	local sendernick=
	parse_hostmask_nick "$sender" 'sendernick'
	# If it isn't in a channel send message back to person who send it,
	# otherwise send in channel
	if ! [[ $2 =~ ^# ]]; then
		channel="$sendernick"
	fi
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command_stdout "$query" "calc")"; then
		# Sanity check on parameters
		parameters="$(tr -d '\n\r\t' <<< "$parameters")"
		if grep -Eq "scale=|read|while|if|for|break|continue|print|return|define|[e|j] *\(" <<< "$parameters"; then
			send_msg "$channel" "${sendernick}: Can't calculate that, it contains a potential unsafe/very slow function."
		elif [[ $parameters =~ \^[0-9]{4,} ]]; then
			send_msg "$channel" "${sendernick}: Some too large numbers."
		else
			# Force some security guards
			local myresult="$(ulimit -t 4; echo "$parameters" | bc -l 2>&1 | head -n 1)"
			send_msg "$channel" "${sendernick}: $myresult"
		fi
		return 1
	fi
	return 0
}
