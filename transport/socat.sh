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
# A transport module using socat

# A list of features supported
# This is set in transport_check_support
transport_check_support=''

# Check if all the stuff needed to use this transport is available
# Return status
#   0 Yes
#   1 No
transport_check_support() {
	type -p socat >/dev/null || {
		echo "ERROR: Can't find socat (needed for this transport)"
		return 1
	}
	type -p mkfifo >/dev/null || {
		echo "ERROR: Can't find mkfifo (needed for this transport)"
		return 1
	}
	# Build transport_supports
	local features="$(socat -V | grep -E 'socat version|define')"
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
	if [[ -z $config_transport_socat_protocol_family ]]; then
		echo "ERROR: you need to set config_transport_socat_use_ipv6 in your config to either 0 or 1."
		return 1
	fi
	# Check for older version
	if grep -q "socat version 1.4" <<< "$features"; then
		# SSL + IPv6 is not supported with socat-1.4.x
		if [[ $config_server_ssl -ne 0 ]]; then
			# list_remove is not yet loaded so we can't use that here...
			transport_supports="$(sed "s/ipv6//" <<< "$transport_supports")"
		fi
		# This is to be sure socat-1.4.x works
		# Modules should normally never set config_* in them
		# This is an exception.
		if [[ -z $config_transport_socat_protocol_family ]]; then
			config_transport_socat_protocol_family="ipv4"
		fi
		# Remember version to find what workaround to use in transport_connect()
		transport_socat_is_14="1"
	else
		transport_socat_is_14="0"
	fi
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
	transport_tmp_dir_file="$(mktemp -dt envbot.socat.XXXXXXXXXX)" || return 1
	# To keep this simple, from client perspective.
	# We WRITE to out and READ from in
	mkfifo "${transport_tmp_dir_file}/in"
	mkfifo "${transport_tmp_dir_file}/out"
	exec 3<&-
	exec 4<&-
	local addrargs socatnewargs
	if [[ $3 -eq 1 ]]; then
		addrargs="OPENSSL"
		# HACK: Support IPv6 with SSL if socat is new enough.
		if [[ $transport_socat_is_14 -eq 0 ]]; then
			if [[ $config_transport_socat_protocol_family = "ipv6" ]]; then
				socatnewargs=",pf=ip6"
			elif [[ $config_transport_socat_protocol_family = "ipv4" ]]; then
				socatnewargs=",pf=ip4"
			fi
		fi
	elif [[ $config_transport_socat_protocol_family = "ipv6" ]]; then
		addrargs="TCP6"
	elif [[ $config_transport_socat_protocol_family = "ipv4" ]]; then
		addrargs="TCP4"
	fi
	# Add in hostname and port.
	addrargs="${addrargs}:${1}:${2}"
	# Should we bind an IP? Then lets do that.
	if [[ $4 ]]; then
		addrargs="${addrargs},bind=$4"
	fi
	# If version 1.5 or later add in extra args
	if [[ $transport_socat_is_14 -eq 0 ]]; then
		addrargs="${addrargs}${socatnewargs}"
	fi
	# If we use SSL check if we should verify.
	if [[ $3 -eq 1 ]] && [[ $config_server_ssl_accept_invalid -eq 1 ]]; then
		addrargs="${addrargs},verify=0"
	fi
	socat STDIO "$addrargs" < "${transport_tmp_dir_file}/out" > "${transport_tmp_dir_file}/in" &
	transport_pid="$!"
	echo "$transport_pid" >> "${transport_tmp_dir_file}/pid"
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
#   0 If Ok
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
	kill -0 "$transport_pid" >/dev/null 2>&1 && echo "$@" >&3
}
