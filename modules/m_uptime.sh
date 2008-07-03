#!/usr/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2008  Arvid Norlander                               #
#  Copyright (C) 2007-2008  Vsevolod Kozlov                               #
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
## Bot's uptime command.
#---------------------------------------------------------------------

module_uptime_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	commands_register "$1" 'uptime' || return 1
	helpentry_module_uptime_description="Provides a command to show bot's uptime."

	helpentry_uptime_uptime_syntax=''
	helpentry_uptime_uptime_description='Shows the uptime for the bot.'
}

module_uptime_UNLOAD() {
	return 0
}

module_uptime_REHASH() {
	return 0
}

module_uptime_handler_uptime() {
	local sender="$1"
	local formatted_time=
	time_format_difference $SECONDS formatted_time
	local target=
	if [[ $2 =~ ^# ]]; then
		target="$2"
	else
		parse_hostmask_nick "$sender" target
	fi
	send_msg "$target" "The bot has been up for $formatted_time."
}
