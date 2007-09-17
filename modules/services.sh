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
# Identify to nickserv

module_services_INIT() {
	echo "on_connect"
	module_services_ghost=0
}

module_services_UNLOAD() {
	unset module_services_ghost
	unset module_services_on_connect
}

module_services_REHASH() {
	return 0
}

# Called for each line on connect
module_services_on_connect() {
	local line="$1"
	if [[ $( echo $line | cut -d' ' -f2 ) == $numeric_ERR_NICKNAMEINUSE  ]]; then # Nick in use
		module_services_ghost=1
	elif [[ $( echo $line | cut -d' ' -f2 ) == $numeric_ERR_ERRONEUSNICKNAME  ]]; then # Erroneous Nickname Being Held...
		module_services_ghost=1
	elif [[ $( echo $line | cut -d' ' -f2 ) == $numeric_RPL_ENDOFMOTD  ]]; then # 376 = End of motd
		if [[ $module_services_ghost == 1 ]]; then
			log_stdout "Recovering ghost"
			send_msg "Nickserv" "GHOST $config_firstnick $config_module_services_nickserv_passwd"
			sleep 2
			send_nick "$config_firstnick"
		fi
		log_stdout "Identifying..."
		send_msg "Nickserv" "IDENTIFY $config_module_services_nickserv_passwd"
		sleep 1
	fi
}
