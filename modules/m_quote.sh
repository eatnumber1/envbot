#!/bin/bash
###########################################################################
#                                                                         #
#  envbot - an irc bot in bash                                            #
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
# Quotes module

module_quote_INIT() {
	echo "after_load on_PRIVMSG"
}

module_quote_UNLOAD() {
	unset module_quote_on_PRIVMSG module_quote_load
	unset module_quote_quotes
}

module_quote_REHASH() {
	module_quote_load
}

module_quote_load() {
	local i=0
	local line=""
	unset module_quote_quotes
	if [[ -r "$config_module_quotes_file" ]]; then
		while read -d $'\n' line ; do
			# Skip empty lines
			if [[ "$line" ]]; then
				module_quote_quotes[$i]="$line"
				(( i++ ))
			fi
		done < "${config_module_quotes_file}"
		log 'Loaded Quotes.'
		return 0
	else
		log "Cannot load '$config_module_quotes_file'. File doesn't exist."
		return 1
	fi
}


module_quote_after_load() {
	# Return code from last command in a function
	# will be return code for the function by default.
	module_quote_load
}


# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_quote_on_PRIVMSG() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local channel="$2"
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "quote")"; then
		local number=$RANDOM
		local myval="${#module_quote_quotes[*]}"
		(( number %= $myval ))
		send_msg "$channel" "${module_quote_quotes[$number]}"
		return 1
	fi
	return 0
}
