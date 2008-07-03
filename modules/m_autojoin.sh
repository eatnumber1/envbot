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
## This module does autojoin after connect.
#---------------------------------------------------------------------

module_autojoin_INIT() {
	modinit_API='2'
	modinit_HOOKS='after_connect'
	helpentry_module_autojoin_description="Provides support for autojoining channels."
}

module_autojoin_UNLOAD() {
	unset module_autojoin_join_from_config
}

module_autojoin_REHASH() {
	module_autojoin_join_from_config
	return 0
}

#---------------------------------------------------------------------
## Autojoin channels from config.
## @Type Private
#---------------------------------------------------------------------
module_autojoin_join_from_config() {
	local channel
	for channel in "${config_module_autojoin_channels[@]}"; do
		# No quotes around channel because second word of it may be a key
		# and list_contains just uses the first 2 arguments so a
		# third one will be ignored.
		if ! list_contains "channels_current" $channel; then
			log_info "Joining $channel"
			# No quotes here because then second argument can be a key
			channels_join $channel
			sleep 2
		fi
	done
}

# Called after bot has connected
module_autojoin_after_connect() {
	module_autojoin_join_from_config
}
