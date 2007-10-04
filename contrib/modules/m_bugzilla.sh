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
# Check bugs using the program bugz and return output from it.
# bugz is a tool to search Gentoo bug reports (or other bugzillas)
# From eix pybugz:
#   Description:         Command line interface to (Gentoo) Bugzilla
# This module therefore depends on:
#   pybugz

# To set bugzilla to use something like this in config:
#config_module_bugzilla_url='https://bugs.gentoo.org/'
# Must end in trailing slash!
# You also need to specify flood limiting
# (how often in seconds)
#config_module_bugzilla_rate='10'


module_bugzilla_INIT() {
	echo 'on_PRIVMSG after_load'
}

module_bugzilla_UNLOAD() {
	unset module_bugzilla_last_query
}

module_bugzilla_REHASH() {
	return 0
}

# Called after module has loaded.
# Check for bugz
module_bugzilla_after_load() {
	type -p bugz &> /dev/null
	if [[ $? -ne 0 ]]; then
		log_error "Couldn't find bugz command line tool. The bugzilla module depend on that tool (emerge pybugz to get it on gentoo)."
		return 1
	fi
	if [[ -z $config_module_bugzilla_url ]]; then
		log_error "Please set config_module_bugzilla_url in config."
		return 1
	fi
	if [[ -z $config_module_bugzilla_url ]]; then
		log_error "Please set config_module_bugzilla_rate in config."
		return 1
	fi
	unset module_bugzilla_last_query
	module_bugzilla_last_query='0'
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
	# If it isn't in a channel send message back to person who send it,
	# otherwise send in channel
	if ! [[ $2 =~ ^# ]]; then
		channel="$(parse_hostmask_nick "$sender")"
	fi
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "bugs search")"; then
		if [[ "$parameters" =~ ^(-(all|closed)\ )?(.+) ]]; then
			local mode="${BASH_REMATCH[2]}"
			local pattern="${BASH_REMATCH[@]: -1}"
				# Simple flood limiting
				if time_check_interval "$module_bugzilla_last_query" "$config_module_bugzilla_rate"; then
					module_bugzilla_last_query="$(date -u +%s)"
					local bugs_parameters=""
					if [[ $mode = "all" ]]; then
						bugs_parameters="-s all"
					elif [[ $mode = "closed" ]]; then
						bugs_parameters="-s CLOSED -s RESOLVED"
					fi
					log_info_file bugzilla.log "$sender made the bot run pybugz search on \"$pattern\""
					local result="$(ulimit -t 4; bugz -fqb "$config_module_bugzilla_url" search $bugs_parameters "$pattern")"
					local chars="$(wc -c <<< "$result")"
					local lines="$(wc -l <<< "$result")"
					local header footer
					if [[ $chars -le 10 ]]; then
						header="No bugs matching \"$pattern\" found"
					elif [[ $lines -gt 1 ]]; then
						header="First bug matching \"$pattern\": "
						footer=" ($lines more bugs found)"
					else
						header="One bug matching \"$pattern\" found: "
					fi
					if [[ $(head -n 1 <<< "$result") =~ \ ([0-9]+)\ +([^ ]+)\ +(.*)$ ]]; then
						local pretty_result="${format_bold}${config_module_bugzilla_url}${BASH_REMATCH[1]}${format_bold}  ${format_bold}Description${format_bold}: ${BASH_REMATCH[3]}  ${format_bold}Assigned To${format_bold}: ${BASH_REMATCH[2]}"
					fi
					send_msg "$channel" "${header}${pretty_result}${footer}"
				else
					log_error_file bugzilla.log "FLOOD DETECTED in bugzilla module"
				fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "bugs search" "pattern"
		fi
		return 1
	elif parameters="$(parse_query_is_command "$query" "bug")"; then
		if [[ "$parameters" =~ ^([0-9]+) ]]; then
			local id="${BASH_REMATCH[1]}"
				local query_time="$(date +%H%M)$sender"
				if [[ "$module_bugzilla_last_query" != "$query_time" ]] ; then
					module_bugzilla_last_query="$query_time"
					log_info_file bugzilla.log "$sender made the bot check with pybugz for bug \"$id\""
					local result="$(ulimit -t 4; bugz -fqb "$config_module_bugzilla_url" get -n "$id" | grep -E 'Title|Status|Resolution')"
					local resultread pretty_result
					local title status resolution
					# Read the data out of the multiline result.
					while read -r resultread; do
						if [[ $resultread =~ ^Title[\ :]+([^ ].*) ]]; then
							title="${BASH_REMATCH[1]}"
						elif [[ $resultread =~ ^Status[\ :]+([^ ].*) ]]; then
							status="${BASH_REMATCH[1]}"
						elif [[ $resultread =~ ^Resolution[\ :]+([^ ].*) ]]; then
							resolution="${BASH_REMATCH[1]}"
						fi
					done <<< "$result"
					# Yes this is a bit of a mess
					if [[ "$title" ]]; then
						# This info is always here
						pretty_result="${format_bold}Bug $id${format_bold} (${format_bold}Status${format_bold} $status"
						# The resolution may not exist, add it if it does.
						if [[ $resolution ]]; then
							pretty_result="${pretty_result}, ${format_bold}Resolution${format_bold} $resolution"
						fi
						# And add the title in. Does not depend on if resolution exist.
						pretty_result="${pretty_result}): $title (${config_module_bugzilla_url}${id})"
					else
						pretty_result="Bug $id not found"
					fi
					send_msg "$channel" "${pretty_result}"
				else
					log_error_file bugzilla.log "FLOOD DETECTED in bugzilla module"
				fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "bug" "id"
		fi
		return 1
	fi
	return 0
}
