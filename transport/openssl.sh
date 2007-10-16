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
#---------------------------------------------------------------------
## A transport module using openssl s_client
#---------------------------------------------------------------------

# A list of features supported
# These are used: ipv4, ipv6, ssl, nossl, bind
transport_supports="ipv4 ipv6 ssl"

# Check if all the stuff needed to use this transport is available
# Return status
#   0 yes
#   1 no
transport_check_support() {
	type -p openssl >/dev/null || {
		echo "ERROR: Can't find openssl (needed for this transport)"
		return 1
	}
	type -p mkfifo >/dev/null || {
		echo "ERROR: Can't find mkfifo (needed for this transport)"
		return 1
	}
	return 0
}

# Try to connect
# Parameters
#   $1 hostname/IP
#   $2 port
#   $3 If 1 use SSL. If the module does not support it, just ignore it.
#   $4 IP to bind to if any and if supported
#      If the module does not support it, just ignore it.
# Return status
#   0 if Ok
#   1 if connection failed
transport_connect() {
	transport_tmp_dir_file="$(mktemp -dt envbot.openssl.XXXXXXXXXX)" || return 1
	# To keep this simple, from client perspective.
	# We WRITE to out and READ from in
	mkfifo "${transport_tmp_dir_file}/in"
	mkfifo "${transport_tmp_dir_file}/out"
	exec 3<&-
	exec 4<&-
	local myargs
	if [[ $config_server_ssl_accept_invalid -eq 1 ]]; then
		myargs="-verify 0"
	else
		myargs="-verify 10"
	fi
	[[ $config_server_ssl_verbose -ne 1 ]] && myargs+=" -quiet"
	openssl s_client -connect "$1:$2" $myargs < "${transport_tmp_dir_file}/out" > "${transport_tmp_dir_file}/in" &
	transport_pid="$!"
	echo "$transport_pid" >> "${transport_tmp_dir_file}/pid"
	exec 3>"${transport_tmp_dir_file}/out"
	exec 4<"${transport_tmp_dir_file}/in"
	# To be able to wait for error.
	sleep 2
	kill -0 "$transport_pid" >/dev/null 2>&1 || return 1
}

# Called to close connection
# No parameters, no return code check
transport_disconnect() {
	# It might not be running.
	kill "$(< "${transport_tmp_dir_file}/pid")" >/dev/null 2>&1
	rm -rf "${transport_tmp_dir_file}"
	exec 3<&-
	exec 4<&-
}

# Return status
#   0 If connection is still alive
#   1 If it isn't.
transport_alive() {
	kill -0 "$transport_pid" >/dev/null 2>&1
}

# Return a line in the variable line.
# Return status
#   0 If Ok
#   1 If connection failed
transport_read_line() {
	read -ru 4 -t $envbot_transport_timeout line
	# Fail.
	[[ $? -ne 0 ]] && return 1
	line=${line//$'\r'/}
}

# Send a line
# Parameters
#   $* send this
# Return code not checked.
transport_write_line() {
	kill -0 "$transport_pid" >/dev/null 2>&1 && echo "$@" >&3
}
