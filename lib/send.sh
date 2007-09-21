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


# Simple flood limiting.
# Note that this doesn't handle this very well:
# seconds:miliseconds message
# 01:999 message
# 02:001 other message
# Then they get too close.
# I think this won't flood us off though.
send_last=0

send_raw() {
	if [[ "$send_last" == "$(date -u +%s)" ]]; then
		sleep 1
	fi
	send_last="$(date -u +%s)"
	send_raw_flood "$@"
}

# $1 = who (channel or nick)
# $* = message
send_msg() {
	local target="$1"
	shift 1
	send_raw "PRIVMSG ${target} :${@}"
}

# $1 = who (channel or nick)
# $* = message
send_notice() {
	local target="$1"
	shift 1
	send_raw "NOTICE ${target} :${@}"
}

# $1 = who (channel or nick)
# $* = message
send_ctcp() {
	local target="$1"
	shift 1
	send_msg "${target}" $'\1'"${@}"$'\1'
}

# $1 = who (channel or nick)
# $* = message
send_nctcp() {
	local target="$1"
	shift 1
	send_notice "${target}" $'\1'"${@}"$'\1'
}

# $1 = new nick
send_nick() {
	local nick="$1"
	send_raw "NICK ${nick}"
}

# $1 = modes to set
send_umodes() {
	send_raw "MODE $server_nick_current $1"
}

# $1 = channel to set them on
# $2 = modes to set
send_modes() {
	send_raw "MODE $1 $2"
}

# $1 = channel to set topic of
# $2 = new topic.
send_topic() {
	send_raw "TOPIC $1 :$2"
}


# This is semi-internal only
# This may flood ourself off. Use send_raw instead in most cases.
send_raw_flood() {
	log_raw_out "$@"
	transport_write_line "$@"$'\r'
}

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

# Module authors: use the wrapper: bot_quit in misc.sh instead!
# $1 = if set, a quit reason
send_quit() {
	local reason=""
	[[ -n "$1" ]] && reason=" :$1"
	send_raw "QUIT${reason}"
}
