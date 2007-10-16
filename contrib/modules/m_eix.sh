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
## Check eix and return output from it.
## @eix eix is a tool to search Gentoo packages<br />
## @eix From eix eix:<br />
## @eix <tt>  Description:         Small utility for searching ebuilds with indexing for fast results</tt>
## @Dependencies This module therefore depends on:<br />
## @Dependencies   Gentoo<br />
## @Dependencies   eix<br />
## @Config_variables You need to specify flood limiting in config.<br />
## @Config_variables (how often in seconds)<br />
## @Config_variables <tt>config_module_eix_rate='5'</tt><br />
#---------------------------------------------------------------------

module_eix_INIT() {
	echo 'on_PRIVMSG after_load'
}

module_eix_UNLOAD() {
	unset module_eix_format_string module_eix_last_query
}

module_eix_REHASH() {
	return 0
}

# Called after module has loaded.
# Check for eix
module_eix_after_load() {
	# Check (silently) for eix
	type -p eix &> /dev/null
	if [[ $? -ne 0 ]]; then
		log_error "Couldn't find eix command line tool. The eix module depend on that tool."
		return 1
	fi
	# Flood limiting.
	unset module_eix_last_query
	module_eix_last_query='0'
}

#---------------------------------------------------------------------
## eix format string.
## @Type Private
#---------------------------------------------------------------------
module_eix_format_string="<category>/${format_bold}<name>${format_bold} \(<availableversionsshort>\) \(${format_bold}<homepage>${format_bold}\): <description>"

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_eix_on_PRIVMSG() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local channel="$2"
	# If it isn't in a channel send message back to person who send it,
	# otherwise send in channel
	if ! [[ $2 =~ ^# ]]; then
		parse_hostmask_nick "$sender" 'channel'
	fi
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command_stdout "$query" "eix")"; then
		if [[ "$parameters" =~ ^(.+) ]]; then
			local pattern="${BASH_REMATCH[1]}"
				# Simple flood limiting
				if time_check_interval "$module_eix_last_query" "$config_module_eix_rate"; then
					module_eix_last_query="$(date -u +%s)"
					log_info_file eix.log "$sender made the bot run eix on \"$pattern\""
					send_msg "$channel" "$(ulimit -t 4; EIX_PRINT_IUSE='false' eix -pSCxs --format "$module_eix_format_string" "$pattern" | head -n 1)"
				else
					log_error_file eix.log "FLOOD DETECTED in eix module"
				fi
		else
			local sendernick
			parse_hostmask_nick "$sender" 'sendernick'
			feedback_bad_syntax "$sendernick" "eix" "pattern"
		fi
		return 1
	fi
	return 0
}
