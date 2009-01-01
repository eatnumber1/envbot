#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2009  Arvid Norlander                               #
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
## Keeps track of latency
#---------------------------------------------------------------------

module_ping_INIT() {
	modinit_API='2'
	modinit_HOOKS='periodic on_PONG'
	module_ping_counter=0
	module_ping_latency=0
	commands_register "$1" 'ping' || return 1
	commands_register "$1" 'latency' || return 1
	helpentry_module_ping_description="Provides latency tracking."

	helpentry_ping_ping_syntax=''
	helpentry_ping_ping_description='Respond to sender with "PONG!"'

	helpentry_ping_latency_syntax=''
	helpentry_ping_latency_description='Report current latency to server.'
}

module_ping_UNLOAD() {
	unset module_ping_counter module_ping_latency
}

module_ping_REHASH() {
	return 0
}

module_ping_periodic() {
	if [[ $module_ping_counter = 5 ]]; then
		send_raw "PING :$envbot_time"
		module_ping_counter=0
	else
		(( module_ping_counter++ ))
	fi
}

module_ping_on_PONG() {
	# Is data numbers only?
	if ! [[ $3 = *[^0-9]* ]]; then
		(( module_ping_latency = envbot_time - $3 ))
	fi
}

module_ping_handler_ping() {
	local target
	local sender_nick
	parse_hostmask_nick "$1" 'sender_nick'
	if [[ $2 =~ ^# ]]; then
		target="$2"
	else
		target="$sender_nick"
	fi
	send_msg "$target" "$sender_nick: PONG!"
}

module_ping_handler_latency() {
	local target
	if [[ $2 =~ ^# ]]; then
		target="$2"
	else
		parse_hostmask_nick "$1" 'target'
	fi
	local msg=
	if [[ $module_ping_latency = 0 ]]; then
		msg="less than one second"
	elif [[ $module_ping_latency = 1 ]]; then
		msg="1 second"
	else
		msg="$module_ping_latency seconds"
	fi
	send_msg "$target" "Latency is $msg"
}
