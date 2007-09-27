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
# This module does autojoin after connect.

module_autojoin_INIT() {
	echo 'after_connect'
}

module_autojoin_UNLOAD() {
	unset module_autojoin_join_from_config
}

module_autojoin_REHASH() {
	module_autojoin_join_from_config
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
