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
# A transport module using socat

# A list of features supported
# This is set in transport_check_support
transport_check_support=''

# Check if all the stuff needed to use this transport is available
# Return status
#   0 yes
#   1 no
transport_check_support() {
	# If anyone can tell me how to check if /dev/tcp is supported
	# without trying to make a connection (that could fail for so
	# many other reasons), please contact me.
	type -p socat >/dev/null || return 1
	type -p mkfifo >/dev/null || return 1
	# Build transport_supports
	local features="$(socat -V | grep 'define')"
	# These seems to always be supported?
	transport_supports="nossl bind"
	if grep -q WITH_IP4 <<< "$features"; then
		transport_supports="$transport_supports ipv4"
	fi
	if grep -q WITH_IP6 <<< "$features"; then
		transport_supports="$transport_supports ipv6"
	fi
	if grep -q WITH_OPENSSL <<< "$features"; then
		transport_supports="$transport_supports ssl"
	fi
	# SSL + IPv6 is not supported with socat :(
	if [[ $config_server_ssl -ne 0 ]]; then
		# list_remove is not yet loaded so we can't use that here...
		transport_supports="$(sed "s/ipv6//" <<< "$transport_supports")"
	fi

	if [[ -z $config_transport_socat_use_ipv6 ]]; then
		echo "ERROR: you need to set config_transport_socat_use_ipv6 in your config to either 0 or 1."
	fi
	return 0
}

# Try to connect
# Parameters
#   $1 hostname/ip
#   $2 port
#   $3 If 1 use SSL. If the module does not support it, just ignore it.
#   $4 IP to bind to if any and if supported
#      If the module does not support it, just ignore it.
# Return status
#   0 if ok
#   1 if connection failed
transport_connect() {
	transport_tmp_dir_file="$(mktemp -dt envbot.socat.XXXXXXXXXX)" || return 1
	# To keep this simple, from client perspective.
	# We WRITE to out and READ from in
	mkfifo "${transport_tmp_dir_file}/in"
	mkfifo "${transport_tmp_dir_file}/out"
	exec 3<&-
	exec 4<&-
	local addrargs
	if [[ $3 -eq 1 ]]; then
		addrargs="OPENSSL"
	elif [[ $config_transport_socat_use_ipv6 -eq 1 ]]; then
		addrargs="TCP6"
	else
		addrargs="TCP4"
	fi
	addrargs="${addrargs}:${1}:${2}"
	if [[ $4 ]]; then
		addrargs="${addrargs},bind=$4"
	fi
	# If we use SSL check if we should verify.
	if [[ $3 -eq 1 ]] && [[ $config_server_ssl_accept_invalid -eq 1 ]]; then
		addrargs="${addrargs},verify=0"
	fi
	socat STDIO "$addrargs" < "${transport_tmp_dir_file}/out" > "${transport_tmp_dir_file}/in" &
	echo $! >> "${transport_tmp_dir_file}/pid"
	exec 3>"${transport_tmp_dir_file}/out"
	exec 4<"${transport_tmp_dir_file}/in"
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

# Return a line in the variable line.
# Return status
#   0 If ok
#   1 If connection failed
transport_read_line() {
	read -ru 4 -t 600 line
	# Fail.
	[[ $? -ne 0 ]] && return 1
	line=${line//$'\r'/}
}

# Send a line
# Parameters
#   $* send this
# Return code not checked.
transport_write_line() {
	echo "$@" >&3
}
