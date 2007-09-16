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
# This module does autojoin after connect.

module_autojoin_INIT() {
	echo "after_connect"
}

module_autojoin_UNLOAD() {
	unset module_autojoin_after_connect
}

module_autojoin_REHASH() {
	return 0
}

module_autojoin_join_from_config() {
	local channel
	for channel in "${config_module_autojoin_channels[@]}"; do
		# No quotes here because then second arugment can be a key
		channels_join $channel
		sleep 2
	done
}

# Called after bot has connected
module_autojoin_after_connect() {
	module_autojoin_join_from_config
}
