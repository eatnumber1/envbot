#!/bin/bash
###########################################################################
#                                                                         #
#   Copyright (c)                                                         #
#     Arvid Norlander <anmaster@kuonet.org>                               #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
###########################################################################

send_raw() {
	log_raw_out "$@"
	echo -e "$@\r" >&3
}
# $1 = who (channel or nick)
# $* = message
send_msg() {
	local nick="$1"
	shift 1
	send_raw "PRIVMSG ${nick} :${@}"
}
# $1 = who (channel or nick)
# $* = message
send_notice() {
	local nick="$1"
	shift 1
	send_raw "NOTICE ${nick} :${@}"
}

# $1 = new nick
send_nick() {
	local nick="$1"
	send_raw "NICK ${nick}"
}

# $1 = modes to set
send_umodes() {
	send_raw "MODE $CurrentNick $1"
}

# $1 = channel to set them on
# $2 = modes to set
send_modes() {
	send_raw "MODE $1 $2"
}

# $1 = if set, a quit reason
send_quit() {
	local reason=""
	[ -n "$1" ] && reason=" :$1"
	send_raw "QUIT${reason}"
}


