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
# Identify to nickserv

module_services_INIT() {
	echo 'on_connect after_load'
}

module_services_UNLOAD() {
	unset module_services_ghost module_services_nickserv_command
}

module_services_REHASH() {
	return 0
}

module_services_after_load() {
	module_services_ghost=0
	if [[ $config_module_services_server_alias -eq 0 ]]; then
		module_services_nickserv_command="PRIVMSG $config_module_services_nickserv_name :"
	else
		module_services_nickserv_command="$config_module_services_nickserv_name "
	fi
}

# Called for each line on connect
module_services_on_connect() {
	local line="$1"
	if [[ $(cut -d' ' -f2 <<< "$line") == $numeric_ERR_NICKNAMEINUSE  ]]; then # Nick in use
		module_services_ghost=1
	elif [[ $(cut -d' ' -f2 <<< "$line") == $numeric_ERR_ERRONEUSNICKNAME  ]]; then # Erroneous Nickname Being Held...
		module_services_ghost=1
	elif [[ $(cut -d' ' -f2 <<< "$line") == $numeric_RPL_ENDOFMOTD ]]; then
		if [[ $config_module_services_style == atheme ]]; then
			send_raw "${module_services_nickserv_command}IDENTIFY $config_firstnick $config_module_services_nickserv_passwd"
		fi
		if [[ $module_services_ghost == 1 ]]; then
			log_stdout "Recovering ghost"
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
