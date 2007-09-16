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
# Channel modes

module_assign_mode_INIT() {
	echo "on_PRIVMSG"
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel)
# $3 = nick
module_assign_mode_on_PRIVMSG() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local sendon_channel="$2"
	local query="$3"
	if [[ "$query" =~ ^${config_listenchar}op.* ]]; then
		query="${query//${config_listenchar}op/}"
		query="${query/^ /}"
		if access_check_owner "$sender"; then
			if [[ $query =~ (#[^ ]+)\ (.*) ]]; then
				local channel="${BASH_REMATCH[1]}"
				local nick="${BASH_REMATCH[2]}"
				send_raw "MODE $channel +o $nick"
			fi
			sleep 2
		else
			access_fail "$sender" "make the bot op somebody" "owner"
		fi
		return 1
	elif [[ "$query" =~ ^${config_listenchar}deop.* ]]; then
		query="${query//${config_listenchar}deop/}"
		query="${query/^ /}"
		if access_check_owner "$sender"; then
			if [[ $query =~ (#[^ ]+)\ (.*) ]]; then
				local channel="${BASH_REMATCH[1]}"
				local nick="${BASH_REMATCH[2]}"
				send_raw "MODE $channel -o $nick"
			fi
			sleep 2
		else
			access_fail "$sender" "make the bot deop somebody" "owner"
		fi
		return 1
	elif [[ "$query" =~ ^${config_listenchar}halfop.* ]]; then
		query="${query//${config_listenchar}halfop/}"
		query="${query/^ /}"
		if access_check_owner "$sender"; then
			if [[ $query =~ (#[^ ]+)\ (.*) ]]; then
				local channel="${BASH_REMATCH[1]}"
				local nick="${BASH_REMATCH[2]}"
				send_raw "MODE $channel +h $nick"
			fi
			sleep 2
		else
			access_fail "$sender" "make the bot halfop somebody" "owner"
		fi
		return 1
	elif [[ "$query" =~ ^${config_listenchar}dehalfop.* ]]; then
		query="${query//${config_listenchar}dehalfop/}"
		query="${query/^ /}"
		if access_check_owner "$sender"; then
			if [[ $query =~ (#[^ ]+)\ (.*) ]]; then
				local channel="${BASH_REMATCH[1]}"
				local nick="${BASH_REMATCH[2]}"
				send_raw "MODE $channel -h $nick"
			fi
			sleep 2
		else
			access_fail "$sender" "make the bot dehalfop somebody" "owner"
		fi
		return 1
	elif [[ "$query" =~ ^${config_listenchar}voice.* ]]; then
		query="${query//${config_listenchar}voice/}"
		query="${query/^ /}"
		if access_check_owner "$sender"; then
			if [[ $query =~ (#[^ ]+)\ (.*) ]]; then
				local channel="${BASH_REMATCH[1]}"
				local nick="${BASH_REMATCH[2]}"
				send_raw "MODE $channel +v $nick"
			fi
			sleep 2
		else
			access_fail "$sender" "make the bot give voice to somebody" "owner"
		fi
		return 1
	elif [[ "$query" =~ ^${config_listenchar}devoiced.* ]]; then
		query="${query//${config_listenchar}devoice/}"
		query="${query/^ /}"
		if access_check_owner "$sender"; then
			if [[ $query =~ (#[^ ]+)\ (.*) ]]; then
				local channel="${BASH_REMATCH[1]}"
				local nick="${BASH_REMATCH[2]}"
				send_raw "MODE $channel -v $nick"
			fi
			sleep 2
		else
			access_fail "$sender" "make the bot take voice from somebody" "owner"
		fi
		return 1
	elif [[ "$query" =~ ^${config_listenchar}protect.* ]]; then
		query="${query//${config_listenchar}protect/}"
		query="${query/^ /}"
		if access_check_owner "$sender"; then
			if [[ $query =~ (#[^ ]+)\ (.*) ]]; then
				local channel="${BASH_REMATCH[1]}"
				local nick="${BASH_REMATCH[2]}"
				send_raw "MODE $channel +a $nick"
			fi
			sleep 2
		else
			access_fail "$sender" "make the bot protect somebody" "owner"
		fi
		return 1
	elif [[ "$query" =~ ^${config_listenchar}deprotect.* ]]; then
		query="${query//${config_listenchar}deprotect/}"
		query="${query/^ /}"
		if access_check_owner "$sender"; then
			if [[ $query =~ (#[^ ]+)\ (.*) ]]; then
				local channel="${BASH_REMATCH[1]}"
				local nick="${BASH_REMATCH[2]}"
				send_raw "MODE $channel -a $nick"
			fi
			sleep 2
		else
			access_fail "$sender" "make the bot deprotect somebody" "owner"
		fi
		return 1
	fi

	return 0
}
