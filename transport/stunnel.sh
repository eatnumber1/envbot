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
# A HACKISH transport module using stunnel

# A list of features supported
# This is set in transport_check_support
transport_supports=""

# Check if all the stuff needed to use this transport is available
# Return status: 0 = yes
#                1 = no
transport_check_support() {
	echo 'WARNING: stunnel support is known to be semi-broken.'
	echo 'For SSL it is better to use gnutls or openssl transports!'
	if [[ $config_transport_stunnel_ireallywantstunnel -ne 1 ]]; then
		local i
		for i in {1..10}; do
			sleep 1
			echo -ne '\a'
		done
		echo "If you really want to use stunnel still add this to your config:"
		echo 'config_transport_stunnel_ireallywantstunnel=1'
		exit 1
	fi
	# If anyone can tell me how to check if /dev/tcp is supported
	# without trying to make a connection (that could fail for so
	# many other reasons), please contact me.
	[[ -x "$config_transport_stunnel_path" ]] || return 1
	# HACKISH: Check if ipv6 is supported
	if "$config_transport_stunnel_path" -version 2>&1 | grep -q 'IPV6'; then
		transport_supports="ipv4 ipv6 ssl"
	else
		transport_supports="ipv4 ssl"
	fi
	return 0
}

# Print a config file for stunnel
# Yes, this is the only way to tell stunnel what to do...
# $1 = Remote hostname
# $2 = Remote port to use
transport_create_config() {
	echo "client = yes"
	echo "verify = $(($config_server_ssl_accept_invalid ? 0: 1))"
	echo "pid = $transport_pid_file"
	echo "output = $transport_output_file"
	echo "[irc]"
	echo "accept = 127.0.0.1:$config_transport_stunnel_localport"
	echo "connect = $1:$2"
	echo "TIMEOUTbusy = 600"
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
	transport_create_config "$1" "$2" | \
		"$config_transport_stunnel_path" -fd 0 || return 1
	exec 3<&-
	exec 3<> "/dev/tcp/127.0.0.1/$config_transport_stunnel_localport" || return 1
}

# Called to close connection
# No parameters, no return code check
transport_disconnect() {
	exec 3<&-

	[[ -f "$transport_pid_file" ]] && kill "$(< "$transport_pid_file")" && rm -f $transport_pid_file
	[[ -f "$transport_output_file" ]] && cat "$transport_output_file" && rm $transport_output_file
}

# Return a line in the variable line.
# Return status: 0 if ok
#                1 if connection failed
transport_read_line() {
	read -ru 3 -t 600 line
	# Fail.
	[[ $? -ne 0 ]] && return 1
	line="${line//$'\r'/}"
}

# Send a line
# $* = send this
# Return code not checked.
transport_write_line() {
	echo "$@" >&3
}
