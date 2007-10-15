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
#---------------------------------------------------------------------
## Functions for sending data to server
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## Simple flood limiting.
## Note that this doesn't handle this very well:<br />
## seconds:milliseconds message<br />
## 01:999 message<br />
## 02:001 other message<br />
## Then they get too close.<br />
## I think this won't flood us off though.<br />
## @Type Private
#---------------------------------------------------------------------
send_last=0

#---------------------------------------------------------------------
## Send a "raw" line to the server.
## @Type API
## @param Line to send
#---------------------------------------------------------------------
send_raw() {
	# Do the flood limiting
	if [[ "$send_last" == "$(date -u +%s)" ]]; then
		sleep 1
	fi
	send_last="$(date -u +%s)"
	send_raw_flood "$@"
}

#---------------------------------------------------------------------
## Send a PRIVMSG
## @Type API
## @param Who (channel or nick)
## @param Message
#---------------------------------------------------------------------
send_msg() {
	local target="$1"
	shift 1
	send_raw "PRIVMSG ${target} :${@}"
}

#---------------------------------------------------------------------
## Send a NOTICE
## @Type API
## @param Who (channel or nick)
## @param Message
#---------------------------------------------------------------------
send_notice() {
	local target="$1"
	shift 1
	send_raw "NOTICE ${target} :${@}"
}

#---------------------------------------------------------------------
## Send a CTCP
## @Type API
## @param Who (channel or nick)
## @param Message
#---------------------------------------------------------------------
send_ctcp() {
	local target="$1"
	shift 1
	send_msg "${target}" $'\1'"${@}"$'\1'
}

#---------------------------------------------------------------------
## Send a NCTCP (ctcp reply)
## @Type API
## @param Who (channel or nick)
## @param Message
#---------------------------------------------------------------------
send_nctcp() {
	local target="$1"
	shift 1
	send_notice "${target}" $'\1'"${@}"$'\1'
}

#---------------------------------------------------------------------
## Send a NICK to change nick
## @Type API
## @param New nick
#---------------------------------------------------------------------
send_nick() {
	local nick="$1"
	send_raw "NICK ${nick}"
}

#---------------------------------------------------------------------
## Send a MODE to change umodes.
## @Type API
## @param Modes to send
#---------------------------------------------------------------------
send_umodes() {
	send_raw "MODE $server_nick_current $1"
}

#---------------------------------------------------------------------
## Send a MODE to change channel modes.
## @Type API
## @param Target channel
## @param Modes to set
#---------------------------------------------------------------------
send_modes() {
	send_raw "MODE $1 $2"
}

#---------------------------------------------------------------------
## Send a TOPIC to change channel topic.
## @Type API
## @param Channel to change topic of
## @param New topic.
#---------------------------------------------------------------------
send_topic() {
	send_raw "TOPIC $1 :$2"
}

#---------------------------------------------------------------------
## This is semi-internal only
## This may flood ourself off. Use send_raw instead in most cases.
## Also this doesn't log the actual line, so used for passwords.
## @Type API
## @param What to log instead (example could be: "NickServ IDENTIFY (password)")
## @param The line to send
#---------------------------------------------------------------------
send_raw_flood_nolog() {
	log_raw_out "<hidden line from logs>: $1"
	transport_write_line "$2"$'\r'
}

#---------------------------------------------------------------------
## This is semi-internal only
## This may flood ourself off. Use send_raw instead in most cases.
## Same syntax as send_raw
## @Type Semi-private
#---------------------------------------------------------------------
send_raw_flood() {
	log_raw_out "$@"
	transport_write_line "$@"$'\r'
}

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

#---------------------------------------------------------------------
## Module authors: use the wrapper: bot_quit in misc.sh instead!
## @Type Private
## @param If set, a quit reason
#---------------------------------------------------------------------
send_quit() {
	local reason=""
	[[ -n "$1" ]] && reason=" :$1"
	send_raw_flood "QUIT${reason}"
}
