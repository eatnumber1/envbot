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

# Join a channel
# $1 the channel to join
# $2 is a channel key, if any.
send_join() {
	local channel="$1"
	local key=""
	[ -n $2 ] && key=" $2"
	send_raw "JOIN ${channel}${key}"
}

# Part a channel
# $1 the channel to part
# $2 is a reason.
send_part() {
	local channel="$1"
	local reason=""
	[ -n $2 ] && reason=" :$2"
	send_raw "PART ${channel}${reason}"
}

