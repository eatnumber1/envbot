#!/bin/bash
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007  EmErgE <halt.system@gmail.com>                     #
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
# Calculate with bc

module_calc_INIT() {
	echo 'on_PRIVMSG after_load FINALISE'
}

module_calc_UNLOAD() {
	module_calc_remove_tmpfile
	unset module_calc_tmpfile
	unset module_calc_create_tmpfile module_calc_remove_tmpfile module_calc_empty_tmpfile
}

module_calc_REHASH() {
	module_calc_remove_tmpfile
	module_calc_create_tmpfile
}

module_calc_FINALISE() {
	module_calc_remove_tmpfile
	return 0
}

module_calc_create_tmpfile() {
	unset module_calc_tmpfile
	module_calc_tmpfile="$(mktemp -t envbot.calc.XXXXXXXXXX)" || return 1
}

module_calc_empty_tmpfile() {
	> "$module_calc_tmpfile"
}

module_calc_remove_tmpfile() {
	if [[ -e "$module_calc_tmpfile" ]]; then
		rm -f "$module_calc_tmpfile"
	fi
}

module_calc_after_load() {
	module_calc_create_tmpfile
	return 0
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_calc_on_PRIVMSG() {
	local sender="$1"
	local channel="$2"
	# If it isn't in a channel send message back to person who send it,
	# otherwise send in channel
	if ! [[ $2 =~ ^# ]]; then
		channel="$(parse_hostmask_nick "$sender")"
	fi
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "calc")"; then
		echo "$parameters"$'\nquit' > "$module_calc_tmpfile"
		local myresult="$(bc -q "$module_calc_tmpfile")"
		send_msg "$channel" "$(parse_hostmask_nick "$sender"): $myresult"
		module_calc_empty_tmpfile
		return 1
	fi
	return 0
}
