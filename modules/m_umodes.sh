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
## Set umodes when connecting
#---------------------------------------------------------------------

module_umodes_INIT() {
	modinit_API='2'
	modinit_HOOKS='after_connect after_load'
	helpentry_module_umodes_description="Provides support for setting umodes on connect."
}

module_umodes_UNLOAD() {
	unset module_umodes_set_modes
}

module_umodes_REHASH() {
	module_umodes_set_modes
	return 0
}

#---------------------------------------------------------------------
## Set the umodes
## @Type Private
#---------------------------------------------------------------------
module_umodes_set_modes() {
	if [[ $config_module_umodes_default_umodes ]]; then
		log_info "Setting umodes: $config_module_umodes_default_umodes"
		send_umodes "$config_module_umodes_default_umodes"
	fi
}

# Called after bot has connected
module_umodes_after_connect() {
	module_umodes_set_modes
}

# Called after bot has connected
module_umodes_after_load() {
	# Check if connected first
	if [[ $server_connected -eq 1 ]]; then
		module_umodes_set_modes
	fi
}
