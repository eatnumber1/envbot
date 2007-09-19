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
# For debugging, report any unknown numerics.

module_check_numerics_INIT() {
	echo "on_numeric"
}

module_check_numerics_UNLOAD() {
	unset module_check_numerics_on_numeric
}

module_check_numerics_REHASH() {
	return 0
}

module_check_numerics_on_numeric() {
	if [[ -z "${numeric[10#${1}]}" ]]; then
		log_stdout "Unknown numeric $1 Data: $2"
	fi
}
