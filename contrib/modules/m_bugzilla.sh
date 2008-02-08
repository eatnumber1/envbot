#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2008  Arvid Norlander                               #
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
## Check bugs using the program bugz and return output from it.
## @pybugz bugz is a tool to search Gentoo bug reports (or other bugzillas)<br />
## @pybugz From eix pybugz:<br />
## @pybugz  Description:         Command line interface to (Gentoo) Bugzilla
## @Dependencies This module therefore depends on:<br />
## @Dependencies   pybugz
## @Config_variables To set bugzilla to use something like this in config:<br />
## @Config_variables <pre>config_module_bugzilla_tracker_name[0]='gentoo'
## @Config_variables  config_module_bugzilla_tracker_url[0]='https://bugs.gentoo.org/'</pre>
## @Config_variables Must end in trailing slash! Also the first entry will be the default.<br />
## @Config_variables You also need to specify flood limiting<br />
## @Config_variables (how often in seconds)<br />
## @Config_variables <tt>config_module_bugzilla_rate='10'</tt>
#---------------------------------------------------------------------

module_bugzilla_INIT() {
	modinit_API='2'
	modinit_HOOKS='after_load'
	commands_register "$1" 'bugs_search' 'bugs search' || return 1
	commands_register "$1" 'bug' || return 1
}

module_bugzilla_UNLOAD() {
	unset module_bugzilla_last_query module_bugzilla_default_bugtracker
	unset module_bugzilla_parse_config module_bugzilla_find_tracker
	hash_reset 'bugzilla_tracker'
}

module_bugzilla_REHASH() {
	module_bugzilla_parse_config
}

#---------------------------------------------------------------------
## Initialize the hash of name -> url mapping
## @Type Private
#---------------------------------------------------------------------
module_bugzilla_parse_config() {
	hash_reset 'bugzilla_tracker'
	local index
	for index in "${!config_module_bugzilla_tracker_name[@]}"; do
		hash_set 'bugzilla_tracker' \
			"${config_module_bugzilla_tracker_name[index]}" \
			"${config_module_bugzilla_tracker_url[index]}"
	done
	module_bugzilla_default_bugtracker="${config_module_bugzilla_tracker_url[0]}"
}

#---------------------------------------------------------------------
## Find what tracker to use from the parameters.
## @param Name of parameter variable.
## @param Name of bugtracker variable.
## @Type Private
#---------------------------------------------------------------------
module_bugzilla_find_tracker() {
	if [[ "${!1}" =~ ^(-(tracker|t)\ +([A-Za-z0-9]+)\ +)(.+) ]]; then
		local tindex="${BASH_REMATCH[3]}"
		# Store result back in variable.
		printf -v "$1" '%s' "${BASH_REMATCH[4]}"
		local turl
		hash_get 'bugzilla_tracker' "$tindex" 'turl'
		if [[ $turl ]]; then
			printf -v "$2" '%s' "$turl"
		else
			feedback_generic_error "$sendernick" "bugs search" "No such bug tracker found."
		fi
	else
		printf -v "$2" '%s' "${module_bugzilla_default_bugtracker}"
	fi
}

# Called after module has loaded.
# Check for bugz
module_bugzilla_after_load() {
	if ! hash bugz > /dev/null 2>&1; then
		log_error "Couldn't find bugz command line tool. The bugzilla module depend on that tool (emerge pybugz to get it on Gentoo)."
		return 1
	fi
	if [[ -z ${config_module_bugzilla_tracker_url[0]} ]]; then
		log_error "Please set at least config_module_bugzilla_url[0] in config."
		return 1
	fi
	if [[ -z ${config_module_bugzilla_tracker_name[0]} ]]; then
		log_error "Please set at least config_module_bugzilla_name[0] in config."
		return 1
	fi
	if [[ -z $config_module_bugzilla_rate ]]; then
		log_error "Please set config_module_bugzilla_rate in config."
		return 1
	fi
	module_bugzilla_parse_config
	unset module_bugzilla_last_query
	module_bugzilla_last_query='0'
}

module_bugzilla_handler_bugs_search() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local channel="$2"
	local sendernick=
	parse_hostmask_nick "$sender" 'sendernick'
	# If it isn't in a channel send message back to person who send it,
	# otherwise send in channel
	if ! [[ $2 =~ ^# ]]; then
		channel="$sendernick"
	fi
	local parameters="$3"
	local bugtracker
	module_bugzilla_find_tracker 'parameters' 'bugtracker'
	if [[ "$parameters" =~ ^(-(all|closed)\ +)?(.+) ]]; then
		local mode="${BASH_REMATCH[2]}"
		local pattern="${BASH_REMATCH[@]: -1}"
			# Simple flood limiting
			if time_check_interval "$module_bugzilla_last_query" "$config_module_bugzilla_rate"; then
				time_get_current 'module_bugzilla_last_query'
				local bugs_parameters=""
				if [[ $mode = "all" ]]; then
					bugs_parameters="-s all"
				elif [[ $mode = "closed" ]]; then
					bugs_parameters="-s CLOSED -s RESOLVED"
				fi
				log_info_file bugzilla.log "$sender made the bot run pybugz search on \"$pattern\""
				# We unset TERM because otherwise bugz output some control codes
				local result="$(unset TERM; ulimit -t 4; bugz -fqb "$bugtracker" search $bugs_parameters "$pattern")"
				local lines="$(wc -l <<< "$result")"
				local header footer
				# Some odd formatting chars are always returned (in some versions of pybugz), so we can't check for empty string.
				if [[ ${#result} -le 10 ]]; then
					header="No bugs matching \"$pattern\" found"
				elif [[ $lines -gt 1 ]]; then
					header="First bug matching \"$pattern\": "
					footer=" ($lines more bugs found)"
				else
					header="One bug matching \"$pattern\" found: "
				fi
				if [[ $(head -n 1 <<< "$result") =~ \ ([0-9]+)\ +([^ ]+)\ +(.*)$ ]]; then
					local pretty_result="${format_bold}${bugtracker}${BASH_REMATCH[1]}${format_bold}  ${format_bold}Description${format_bold}: ${BASH_REMATCH[3]}  ${format_bold}Assigned To${format_bold}: ${BASH_REMATCH[2]}"
				fi
				send_msg "$channel" "${header}${pretty_result}${footer}"
			else
				log_error_file bugzilla.log "FLOOD DETECTED in bugzilla module"
			fi
	else
		feedback_bad_syntax "$sendernick" "bugs search" "[-t tracker] [-(all|closed)] <pattern>"
	fi
}

module_bugzilla_handler_bug() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local channel="$2"
	local sendernick=
	parse_hostmask_nick "$sender" 'sendernick'
	# If it isn't in a channel send message back to person who send it,
	# otherwise send in channel
	if ! [[ $2 =~ ^# ]]; then
		channel="$sendernick"
	fi
	local parameters="$3"
	local bugtracker
	module_bugzilla_find_tracker 'parameters' 'bugtracker'
	# Extract bug ID
	if [[ "$parameters" =~ ^([0-9]+) ]]; then
		local id="${BASH_REMATCH[1]}"
			# Simple flood limiting
			if time_check_interval "$module_bugzilla_last_query" "$config_module_bugzilla_rate"; then
				time_get_current 'module_bugzilla_last_query'
				log_info_file bugzilla.log "$sender made the bot check with pybugz for bug \"$id\""
				# We unset TERM because otherwise bugz output some control codes
				local result="$(unset TERM; ulimit -t 4; bugz -fqb "$bugtracker" get -n "$id" | grep -E 'Title|Status|Resolution')"
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
						pretty_result+=", ${format_bold}Resolution${format_bold} $resolution"
					fi
					# And add the title in. Does not depend on if resolution exist.
					pretty_result+="): $title (${bugtracker}${id})"
				else
					pretty_result="Bug $id not found"
				fi
				send_msg "$channel" "${pretty_result}"
			else
				log_error_file bugzilla.log "FLOOD DETECTED in bugzilla module"
			fi
	else
		feedback_bad_syntax "$sendernick" "bug" "[-t tracker] <id>"
	fi
}
