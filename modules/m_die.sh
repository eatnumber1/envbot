#!/bin/bash
# -*- coding: UTF8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007  Arvid Norlander                                    #
#  Copyright (C) 2007  EmErgE <halt.system@gmail.com>                     #
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
## Quit the bot.
#---------------------------------------------------------------------

module_die_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	commands_register "$1" 'die' || return 1
	commands_register "$1" 'restart' || return 1
}

module_die_UNLOAD() {
	return 0
}

module_die_REHASH() {
	return 0
}

module_die_handler_die() {
	local sender="$1"
	if access_check_owner "$sender"; then
		local parameters="$3"
		access_log_action "$sender" "made the bot die with reason: $parameters"
		bot_quit "$parameters"
	else
		access_fail "$sender" "make the bot die" "owner"
	fi
}

module_die_handler_restart() {
	local sender="$1"
	if access_check_owner "$sender"; then
		local parameters="$3"
		access_log_action "$sender" "made the bot restart with reason: $parameters"
		bot_restart "$parameters"
	else
		access_fail "$sender" "make the bot restart" "owner"
	fi
}
