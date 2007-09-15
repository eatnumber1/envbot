#!/bin/bash
###########################################################################
#                                                                         #
#   Copyright (c)                                                         #
#     Arvid Norlander <anmaster@kuonet.org>                               #
#     EmErgE <halt.system@gmail.com>                                      #
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
# Simple FAQ module

die_INIT() {
	echo "on_PRIVMSG"
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
die_on_PRIVMSG() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local channel="$2"
	local query="$3"
	if [[ "$query" =~ ^${listenchar}die.* ]]; then
		query="${query//${listenchar}die/}"
		query="${query/# /}"
		if access_check_owner "$sender"; then
				send_quit "$query"
				killall "./bashbot"
			fi
			sleep 2
		else
			access_fail "$sender" "make the bot die" "owner"
		fi
		return 1
	if [[ "$query" =~ ^${listenchar}part.* ]]; then
		query="${query//${listenchar}part/}"
		query="${query/# /}"
		if access_check_owner "$sender"; then
			if [[ $query =~ ([^ ]+)\ (.*) ]]; then
				local channel="${BASH_REMATCH[1]}"
				local message="${BASH_REMATCH[2]}"
				channels_part "$channel $message"
			fi
			sleep 2
		else
			access_fail "$sender" "make the bot part channel" "owner"
		fi
		return 1
	elif [[ "$query" =~ ^${listenchar}join.* ]]; then
		query="${query//${listenchar}oin/}"
		query="${query/# /}"
		if access_check_owner "$sender"; then
			if [[ $query =~ ([^ ]+)(\ .*) ]]; then
				local channel="${BASH_REMATCH[1]}"
				local key="${BASH_REMATCH[2]}"
				channels_join "${channel}${key}"
			fi
			sleep 2
		else
			access_fail "$sender" "make the join channel" "owner"
		fi
		return 1
	fi

	return 0
}
