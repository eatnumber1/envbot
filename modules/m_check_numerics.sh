#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2008  Arvid Norlander                               #
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
## For debugging, report any unknown numerics.
#---------------------------------------------------------------------

module_check_numerics_INIT() {
	modinit_API='2'
	modinit_HOOKS='on_numeric'
	helpentry_module_check_numerics_description="Debugging module to check if any numeric we get is unknown."
}

module_check_numerics_UNLOAD() {
	return 0
}

module_check_numerics_REHASH() {
	return 0
}

module_check_numerics_on_numeric() {
	# Make sure it is in base 10 here.
	if [[ -z "${numerics[10#${1}]}" ]]; then
		log_warning_file unknown_data.log "Unknown numeric $1 Data: $2"
	fi
}
