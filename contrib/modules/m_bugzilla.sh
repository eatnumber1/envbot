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
# Check bugz and return output from it.
# bugz is a tool to search Gentoo bug reports (or other bugzillas)
# From eix pybugz:
#   Description:         Command line interface to (Gentoo) Bugzilla
# This module therefore depends on:
#   pybugz

# To set default bugzilla to use something like this in config:
# config_module_bugzilla_url='https://bugs.gentoo.org/'



module_bugzilla_INIT() {
	echo "on_PRIVMSG after_load"
}

module_bugzilla_UNLOAD() {
	unset module_bugzilla_last_query
	unset module_bugzilla_on_PRIVMSG module_bugzilla_after_load
}

module_bugzilla_REHASH() {
	return 0
}

# Called after module has loaded.
# Check for bugz
module_bugzilla_after_load() {
	# Check (silently) for sqlite3
	type -p bugz &> /dev/null
	if [[ $? -ne 0 ]]; then
		log_stdout "Couldn't find bugz command line tool. The bugzilla module depend on that tool (emerge pybugz to get it on gentoo)."
		return 1
	fi
	if [[ -z $config_module_bugzilla_url ]]; then
		log_stdout "Please set config_module_bugzilla_url in config. The bugzilla module depend on that tool (emerge pybugz to get it on gentoo)."
		return 1
	fi
	unset module_bugzilla_last_query
	module_bugzilla_last_query='null'
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_bugzilla_on_PRIVMSG() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local channel="$2"
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "bugs search")"; then
		if [[ "$parameters" =~ ^(-(all|closed)\ )?(.+) ]]; then
			local mode="${BASH_REMATCH[2]}"
			local pattern="${BASH_REMATCH[@]: -1}"
				# Simple flood limiting
				local query_time="$(date +%H%M)$sender"
				if [[ "$module_bugzilla_last_query" != "$query_time" ]] ; then
					module_bugzilla_last_query="$query_time"
					local bugs_parameters
					if [[ $mode = "all" ]]; then
						bugs_parameters="-s all"
					elif [[ $mode = "closed" ]]; then
						bugs_parameters="-s CLOSED -s RESOLVED"
					else
						bugs_parameters=""
					fi
					log_to_file bugs.log "$sender made the bot run pybugz on \"$pattern\""
					local result="$(bugz -fqb "$config_module_bugzilla_url" search $bugs_parameters "$pattern")"
					local chars="$(wc -c <<< "$result")"
					local lines="$(wc -l <<< "$result")"
					local header
					if [[ $chars -le 10 ]]; then
						header="No bugs matching \"$pattern\" found"
					elif [[ $lines -gt 1 ]]; then
						header="Found $lines result matching \"$pattern\". Only showing first: "
					else
						header="One bug matching \"$pattern\" found: "
					fi
					if [[ $(head -n 1 <<< "$result") =~ \ ([0-9]+)\ +([^ ]+)\ +(.*)$ ]]; then
						local pretty_result="${format_bold}Id${format_bold}: ${BASH_REMATCH[1]}  ${format_bold}Assigned To${format_bold}: ${BASH_REMATCH[2]}  ${format_bold}Description${format_bold}: ${BASH_REMATCH[3]}"
					fi
					send_msg "$channel" "${header}${pretty_result}"
				else
					log_stdout "ERROR: FLOOD DETECTED in bugzilla module"
				fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "bugs search" "pattern"
		fi
		return 1
	fi
	return 0
}
