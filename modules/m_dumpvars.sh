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
## Debug module, dump all variables to console.
#---------------------------------------------------------------------

module_dumpvars_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	commands_register "$1" 'dumpvars'

}

module_dumpvars_UNLOAD() {
	return 0
}

module_dumpvars_REHASH() {
	return 0
}

module_dumpvars_handler_dumpvars() {
	local sender="$1"
	if access_check_owner "$sender"; then
		# This is hackish, we only display
		# lines unique to "file" 1.
		# Also remove one variable that may fill our scrollback.
		access_log_action "$sender" "a dump of variables"
		comm -2 -3 <(declare) <(declare -f) | grep -Ev '^module_quote_quotes'
	else
		access_fail "$sender" "dump variables to STDOUT" "owner"
	fi
}
