#!/bin/bash
# -*- coding: UTF8 -*-
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
#---------------------------------------------------------------------
## Identify to NickServ
#---------------------------------------------------------------------

module_services_INIT() {
	modinit_API='2'
	modinit_HOOKS='on_connect after_load after_disconnect'
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
	if [[ "$line" =~ ^:[^\ ]+\ +([0-9]{3})\ +([^ ]+)\ +(.*) ]]; then
		local numeric="${BASH_REMATCH[1]}"
		local numeric="${BASH_REMATCH[1]}"
		# Check if this is a numeric we will handle.
		case "$numeric" in
			"$numeric_ERR_NICKNAMEINUSE"|"$numeric_ERR_ERRONEUSNICKNAME")
				module_services_ghost=1
				;;
			"$numeric_RPL_ENDOFMOTD"|"$numeric_ERR_NOMOTD")
				if [[ $config_module_services_style == 'atheme' ]]; then
					send_raw_flood_nolog "NickServ IDENTIFY (password)" "${module_services_nickserv_command}IDENTIFY $config_firstnick $config_module_services_nickserv_passwd"
				fi
				if [[ $module_services_ghost == 1 ]]; then
					log_info_stdout "Recovering ghost"
					send_raw_flood_nolog "NickServ GHOST (password)" "${module_services_nickserv_command}GHOST $config_firstnick $config_module_services_nickserv_passwd"
					# Try to release too, just in case.
					send_raw_flood_nolog "NickServ RELEASE (password)" "${module_services_nickserv_command}RELEASE $config_firstnick $config_module_services_nickserv_passwd"
					sleep 2
					send_nick "$config_firstnick"
					# HACK: This is a workaround for bug #21
					server_nick_current="$config_firstnick"
				fi
				log_info_stdout "Identifying..."
				if [[ $config_module_services_style != 'atheme' ]]; then
					send_raw_flood_nolog "NickServ IDENTIFY (password)" "${module_services_nickserv_command}IDENTIFY $config_module_services_nickserv_passwd"
				fi
				sleep 1
				;;
		esac
	fi
}

module_services_after_disconnect() {
	# Reset state.
	module_services_ghost=0
}
