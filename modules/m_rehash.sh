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
## Rehashing
#---------------------------------------------------------------------

module_rehash_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	commands_register "$1" 'rehash' || return 1
}

module_rehash_UNLOAD() {
	unset module_rehash_dorehash
}

module_rehash_REHASH() {
	return 0
}

#---------------------------------------------------------------------
## Rehash config
## @Type Private
## @param Sender
#---------------------------------------------------------------------
module_rehash_dorehash() {
	local sender="$1" status_message
	config_rehash
	local status=$?
	case $status in
		0) status_message="Rehash successful" ;;
		2) status_message="The new config is not the same version as the bot. Rehash won't work." ;;
		3) status_message="Failed to source it, but the bot should not be in an undefined state." ;;
		4) status_message="Configuration validation on new config failed, but the bot should not be in an undefined state." ;;
		5) status_message="Failed to source it and the bot may be in an undefined state." ;;
		*) status_message="Unknown error (code $status)" ;;
	esac
	local sendernick
	parse_hostmask_nick "$sender" 'sendernick'
	send_msg "$sendernick" "$status_message"
}

module_rehash_handler_rehash() {
	local sender="$1"
	if access_check_owner "$sender"; then
		access_log_action "$sender" "did a rehash"
		module_rehash_dorehash "$sender"
	else
		access_fail "$sender" "load a module" "owner"
	fi
}
