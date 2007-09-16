#!/bin/bash
###########################################################################
#                                                                         #
#   Copyright (c)                                                         #
#     Arvid Norlander <anmaster@kuonet.org>                               #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
###########################################################################
# Set umodes when connecting

module_umodes_INIT() {
	echo "after_connect"
}

module_umodes_UNLOAD() {
	unset module_connect_umodes_after_connect
}

module_umodes_REHASH() {
	return 0
}

# Called after bot has connected
module_umodes_after_connect() {
	if [[ $config_module_umodes_default_umodes ]]; then
		log "Setting umodes: $config_module_umodes_default_umodes"
		send_umodes "$config_module_umodes_default_umodes"
	fi
}
