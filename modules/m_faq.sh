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
## Simple FAQ module
#---------------------------------------------------------------------

module_faq_INIT() {
	echo 'after_load on_PRIVMSG'
}

module_faq_UNLOAD() {
	unset module_faq_array module_faq_last_query
	unset module_faq_load
}

module_faq_REHASH() {
	module_faq_load
}

#---------------------------------------------------------------------
## Load or reload FAQ items
## @Type Private
#---------------------------------------------------------------------
module_faq_load() {
	local i=0
	unset module_faq_array
	if [[ -z "$config_module_faq_file" ]]; then
		log_error "faq module: You need to set config_module_faq_file in your config!"
		return 1
	elif [[ -r "$config_module_faq_file" ]]; then
		while read -d $'\n' line ;do
			# Skip empty lines
			if [[ "$line" ]]; then
				(( i++ ))
				module_faq_array[$i]="$line"
			fi
		done < "${config_module_faq_file}"
		log_info 'Loaded FAQ items'
		return 0
	else
		log_error "faq module: Cannot load '${config_module_faq_file}'. File doesn't exist or can't be read."
		return 1
	fi
}

# Called after module has loaded.
module_faq_after_load() {
	unset module_faq_last_query
	module_faq_last_query='null'
	module_faq_load
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_faq_on_PRIVMSG() {
	local sender="$1"
	local channel="$2"
	# If it isn't in a channel send message back to person who send it,
	# otherwise send in channel
	if ! [[ $2 =~ ^# ]]; then
		channel="$(parse_hostmask_nick "$sender")"
	fi
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "faq")"; then
		if [[ "$parameters" =~ ^(.+) ]]; then
			query="${BASH_REMATCH[1]}"
			if [[ "$query" == "reload" ]]; then
				if access_check_capab "faq_admin" "$sender" "GLOBAL"; then
					send_msg "$channel" "Reloading FAQ items..."
					module_faq_load
					send_msg "$channel" "Done."
				else
					access_fail "$sender" "reload faq items" "faq_admin"
				fi
				return 1
			fi
			local query_time="$(date +%H%M)$line"
			if [[ "$module_faq_last_query" != "$query_time" ]] ; then # Must be atleast 1 min old or different query...
				module_faq_last_query="$query_time"
				if [[ "$query" =~ ^\ *([0-9]+)\ *$ ]]; then
					local index="${BASH_REMATCH[1]}"
					if [[ "${module_faq_array[$index]}" ]]; then
						send_msg "$channel" "${module_faq_array[$index]}"
					else
						send_msg "$channel" "That FAQ item doesn't exist"
					fi
				# Check length of search to be at least 3 chars
				elif [[ "${#query}" -ge 3 ]] ; then
					local i=0
					while [[ $i -lt "${#module_faq_array[*]}" ]] ; do
						(( i++ ))
						# FIXME: This code is hard to read.
						# This module needs rewriting...
						if grep -qiFm 1 "$query" <<< "${module_faq_array[$i]}" ; then
							send_msg "$channel" "${module_faq_array[$i]}"
							break 1
						fi
					done
				fi
			else
				log_error "FLOOD DETECTED in FAQ module"
			fi
			return 1
		fi
	fi
	return 0
}
