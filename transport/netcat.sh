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
## A transport module using netcat
#---------------------------------------------------------------------

# A list of features supported
# These are used: ipv4, ipv6, ssl, nossl, bind
# Yes I know some versions of netcat support encryption and some
# other ones support IPv6. I used GNU netcat and I couldn't find
# a way to detect what is supported in current netcat.
# Also those other netcat variants require you to pass some command
# line argument to enable use of IPv6. (nc6 doesn't)
# netcat got to many problems, use either dev-tcp or socat for
# non-SSL transport really!
transport_supports="ipv4 nossl bind"

# Check if all the stuff needed to use this transport is available
# Return status
#   0 yes
#   1 no
transport_check_support() {
	[[ -x "$config_transport_netcat_path" ]] ||  {
		log_fatal "Can't find netcat (needed for this transport)"
		return 1
	}
	hash mkfifo >/dev/null 2>&1 ||  {
		log_fatal "Can't find mkfifo (needed for this transport)"
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
	transport_tmp_dir_file="$tmp_home"
	# To keep this simple, from client perspective.
	# We WRITE to out and READ from in
	[[ -e "${transport_tmp_dir_file}/transport-in" ]] && rm "${transport_tmp_dir_file}/transport-in"
	[[ -e "${transport_tmp_dir_file}/transport-out" ]] && rm "${transport_tmp_dir_file}/transport-out"
	mkfifo "${transport_tmp_dir_file}/transport-in"
	mkfifo "${transport_tmp_dir_file}/transport-out"
	exec 3<&-
	exec 4<&-
	local myargs
	if [[ $4 ]]; then
		myargs="-s $4"
	fi
	"$config_transport_netcat_path" "$1" "$2" < "${transport_tmp_dir_file}/transport-out" > "${transport_tmp_dir_file}/transport-in" &
	transport_pid="$!"
	echo "$transport_pid" >> "${transport_tmp_dir_file}/transport-pid"
	exec 3>"${transport_tmp_dir_file}/transport-out"
	exec 4<"${transport_tmp_dir_file}/transport-in"
	# To be able to wait for error.
	sleep 2
	kill -0 "$transport_pid" >/dev/null 2>&1 || return 1
	time_get_current 'transport_lastvalidtime'
}

# Called to close connection
# No parameters, no return code check
transport_disconnect() {
	# It might not be running.
	kill "$(< "${transport_tmp_dir_file}/transport-pid")" >/dev/null 2>&1
	exec 3<&-
	exec 4<&-
	# To force code to consider this disconnected.
	transport_lastvalidtime=0
}

# Return status
#   0 If connection is still alive
#   1 If it isn't.
transport_alive() {
	kill -0 "$transport_pid" >/dev/null 2>&1 || return 1
	local newtime=
	time_get_current 'newtime'
	(( newtime - transport_lastvalidtime > 300 )) && return 1
	return 0
}

# Return a line in the variable line.
# Return status
#   0 If Ok
#   1 If connection failed
transport_read_line() {
	read -ru 4 -t $envbot_transport_timeout line
	# Fail.
	if [[ $? -ne 0 ]]; then
		return 1
	else
		time_get_current 'transport_lastvalidtime'
	fi
	line=${line//$'\r'/}
}

# Send a line
# Parameters
#   $* send this
# Return code not checked.
transport_write_line() {
	kill -0 "$transport_pid" >/dev/null 2>&1 && echo "$*" >&3
}
