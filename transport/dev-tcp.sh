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
# A transport module using /dev/tcp

# A list of features supported
# These are used: ipv4, ipv6, ssl, nossl, bind
transport_supports="ipv4 ipv6 nossl"

# Check if all the stuff needed to use this transport is available
# Return status
#   0 yes
#   1 no
transport_check_support() {
	# If anyone can tell me how to check if /dev/tcp is supported
	# without trying to make a connection (that could fail for so
	# many other reasons), please contact me.
	echo "NOTE: It is possible that this transport is not supported on your system"
	echo "      However, there is no way it can be checked except trying to connect."
	echo "      If you see an error below try netcat or socat transport instead."
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
	exec 3<&-
	exec 3<> "/dev/tcp/${1}/${2}"
}

# Called to close connection
# No parameters, no return code check
transport_disconnect() {
	exec 3<&-
}

# Return status
#   0 If connection is still alive
#   1 If it isn't.
# FIXME: This is broken...
transport_alive() {
	return 0
}

# Return a line in the variable line.
# Return status
#   0 If Ok
#   1 If connection failed
transport_read_line() {
	read -ru 3 -t $envbot_transport_timeout line
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
