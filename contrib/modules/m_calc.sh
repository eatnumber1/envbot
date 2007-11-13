#!/bin/bash
# -*- coding: UTF8 -*-
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
	modinit_API='2'
	modinit_HOOKS=''
	commands_register "$1" 'calc' || return 1
}

module_calc_UNLOAD() {
	return 0
}

module_calc_REHASH() {
	return 0
}

module_calc_handler_calc() {
	local sender="$1"
	local channel="$2"
	local sendernick=
	parse_hostmask_nick "$sender" 'sendernick'
	# If it isn't in a channel send message back to person who send it,
	# otherwise send in channel
	if ! [[ $2 =~ ^# ]]; then
		channel="$sendernick"
	fi
	local parameters="$3"

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

}
