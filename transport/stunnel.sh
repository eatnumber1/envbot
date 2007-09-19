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
# A HACKISH transport module using socat

# A list of features supported
# These are used: ipv4, ipv6, ssl, bind
transport_supports="ipv4 ipv6 ssl"


# Check if all the stuff needed to use this transport is available
# Return status: 0 = yes
#                1 = no
transport_check_support() {
	# If anyone can tell me how to check if /dev/tcp is supported
	# without trying to make a connection (that could fail for so
	# many other reasons), please contact me.
	[[ -x "$config_transport_stunnel_path" ]] || return 1
	return 0
}

# $1 = Local port to use
# $2 = Remote hostname
# $3 = Remote port to use
# $4 = PID file to use
# $5 = Output file
transport_create_config() {
	echo "client = yes"
	echo "verify = 0"
	echo "pid = $4"
	echo "output = $5"
	echo "[irc]"
	echo "accept = 127.0.0.1:$1"
	echo "connect = $2:$3"
	echo "TIMEOUTidle = 600"
}


# Try to connect
# Return status: 0 if ok
#                1 if connection failed
# $1 = hostname/ip
# $2 = port
# $3 = If 1 use SSL. If the module does not support it, just ignore it.
# $3 = IP to bind to if any and if supported
#      If the module does not support it, just ignore it.
transport_connect() {
	transport_pid_file="$(mktemp -t envbot.stunnel.pid.XXXXXXXXXX)" || return 1
	transport_output_file="$(mktemp -t envbot.stunnel.output.XXXXXXXXXX)" || return 1
	transport_create_config \
		"$config_transport_stunnel_localport" "$1" "$2" "$transport_pid_file" "$transport_output_file" | \
		"$config_transport_stunnel_path" -fd 0
	exec 3<&-
	exec 3<> "/dev/tcp/127.0.0.1/$config_transport_stunnel_localport"
}

# Called to close connection
# No parameters, no return code check
transport_disconnect() {
	exec 3<&-

	[[ -f "$transport_pid_file" ]] && kill "$(cat "$transport_pid_file")" && rm $transport_pid_file
	[[ -f "$transport_output_file" ]] && rm $transport_output_file
}

# Return a line in the variable line.
# Return status: 0 if ok
#                1 if connection failed
transport_read_line() {
	read -ru 3 -t 600 line
	# Fail.
	[[ $? -ne 0 ]] && return 1
	line=${line//$'\r'/}
}

# Send a line
# $* = send this
# Return code not checked.
transport_write_line() {
	echo -e "$@" >&3
}
