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
## Allow owners to make the bot eval any code<br />
## THIS IS FOR DEBUGGING ONLY!!!! Don't use it in other cases
#---------------------------------------------------------------------

module_eval_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	commands_register "$1" 'eval' || return 1
}

module_eval_UNLOAD() {
	return 0
}

module_eval_REHASH() {
	return 0
}

module_eval_handler_eval() {
	# Accept anywhere
	local sender="$1"
	if access_check_owner "$sender"; then
		local parameters="$3"
		access_log_action "$sender" "did eval with: $parameters"
		eval "$parameters"
	else
		access_fail "$sender" "eval a command" "owner"
	fi
}
