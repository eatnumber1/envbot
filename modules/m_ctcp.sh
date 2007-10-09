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
# Handle CTCP

module_ctcp_INIT() {
	echo 'after_load on_PRIVMSG'
}

module_ctcp_UNLOAD() {
	return 0
}

module_ctcp_REHASH() {
	return 0
}

module_ctcp_after_load() {
	if [[ -z $config_module_ctcp_version_reply ]]; then
		log_error "VERSION reply (config_module_ctcp_version_reply) must be set in config to use CTCP module."
		return 1
	fi
}


# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_ctcp_on_PRIVMSG() {
	local sender="$1"
	local query="$3"
	# We can't use regex here. For some unknown reason bash drops \001 from
	# regex.
	if [[ $query = $'\001'* ]]; then
		# Get rid of \001 in the string.
		local data="${query//$'\001'}"
		local ctcp_command ctcp_parameters
		# Split it up into command and any parameters.
		read -r ctcp_command ctcp_parameters <<< "$data"
		case "$ctcp_command" in
			"VERSION")
				send_nctcp "$(parse_hostmask_nick "$sender")" "VERSION $config_module_ctcp_version_reply"
				;;
			"TIME")
				send_nctcp "$(parse_hostmask_nick "$sender")" "TIME $(date +'%Y-%m-%d %k:%M:%S')"
				;;
			"PING")
				send_nctcp "$(parse_hostmask_nick "$sender")" "PING $ctcp_parameters"
				;;
		esac
		return 1
	fi
	return 0
}
