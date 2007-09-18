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
	echo "on_connect after_load"
	module_services_ghost=0
}

module_services_UNLOAD() {
	unset module_services_ghost module_services_nickserv_command
	unset module_services_on_connect module_services_after_load
}

module_services_REHASH() {
	return 0
}

module_services_after_load() {
	if [[ $config_module_services_server_alias -eq 0 ]]; then
		module_services_nickserv_command="PRIVMSG $config_module_services_nickserv_name :"
	else
		module_services_nickserv_command="$config_module_services_nickserv_name "
	fi
}

# Called for each line on connect
module_services_on_connect() {
	local line="$1"
	if [[ $( echo $line | cut -d' ' -f2 ) == $numeric_ERR_NICKNAMEINUSE  ]]; then # Nick in use
		module_services_ghost=1
	elif [[ $( echo $line | cut -d' ' -f2 ) == $numeric_ERR_ERRONEUSNICKNAME  ]]; then # Erroneous Nickname Being Held...
		module_services_ghost=1
	elif [[ $( echo $line | cut -d' ' -f2 ) == $numeric_RPL_ENDOFMOTD  ]]; then # 376 = End of motd
		if [[ $config_module_services_style == atheme ]]; then
			send_raw "${module_services_nickserv_command}IDENTIFY $config_firstnick $config_module_services_nickserv_passwd"
		fi
		if [[ $module_services_ghost == 1 ]]; then
			log_stdout "Recovering ghost"
			sleep 1
			send_raw "${module_services_nickserv_command}GHOST $config_firstnick $config_module_services_nickserv_passwd"
			# Try to release too, just in case.
			send_raw "${module_services_nickserv_command}RELEASE $config_firstnick $config_module_services_nickserv_passwd"
			sleep 2
			send_nick "$config_firstnick"
		fi
		log_stdout "Identifying..."
		if [[ $config_module_services_style != atheme ]]; then
			send_raw "${module_services_nickserv_command}IDENTIFY $config_module_services_nickserv_passwd"
		fi
		sleep 1
	fi
}
