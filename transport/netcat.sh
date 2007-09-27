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
# A transport module using netcat

# A list of features supported
# These are used: ipv4, ipv6, ssl, nossl, bind
# Yes I know some versions of netcat support encryption and some
# other ones support ipv6. I used GNU netcat and I couldn't find
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
	# If anyone can tell me how to check if /dev/tcp is supported
	# without trying to make a connection (that could fail for so
	# many other reasons), please contact me.
	[[ -x "$config_transport_netcat_path" ]] || return 1
	type -p mkfifo >/dev/null || return 1
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
	transport_tmp_dir_file="$(mktemp -dt envbot.netcat.XXXXXXXXXX)" || return 1
	# To keep this simple, from client perspective.
	# We WRITE to out and READ from in
	mkfifo "${transport_tmp_dir_file}/in"
	mkfifo "${transport_tmp_dir_file}/out"
	exec 3<&-
	exec 4<&-
	local myargs
	if [[ $4 ]]; then
		myargs="-s $4"
	fi
	"$config_transport_netcat_path" "$1" "$2" < "${transport_tmp_dir_file}/out" > "${transport_tmp_dir_file}/in" &
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
	kill -0 "$transport_pid" >/dev/null 2>&1 && echo "$@" >&3
}
