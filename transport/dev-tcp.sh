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
# A transport module using /dev/tcp

# A list of features supported
# These are used: ipv4, ipv6, ssl, nossl, bind
transport_supports="ipv4 ipv6 nossl"

# Check if all the stuff needed to use this transport is available
# Return status: 0 = yes
#                1 = no
transport_check_support() {
	# If anyone can tell me how to check if /dev/tcp is supported
	# without trying to make a connection (that could fail for so
	# many other reasons), please contact me.
	return 0
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
	exec 3<&-
	exec 3<> "/dev/tcp/${1}/${2}"
}

# Called to close connection
# No parameters, no return code check
transport_disconnect() {
	exec 3<&-
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
	echo "$@" >&3
}
