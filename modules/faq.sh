#!/bin/bash
###########################################################################
#                                                                         #
#   Copyright (c)                                                         #
#     Arvid Norlander <anmaster@kuonet.org>                               #
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

module_faq_INIT() {
	echo "after_load on_PRIVMSG"
}

module_faq_UNLOAD() {
	unset module_faq_array module_faq_last_query
	unset module_faq_load module_faq_after_load module_faq_on_PRIVMSG
}

module_faq_REHASH() {
	module_faq_load
}

# Load or reload FAQ items
module_faq_load() {
	local i=0
	unset module_faq_array
	while read -d $'\n' line ;do
		i=$((i+1))
		module_faq_array[$i]="$line"
	done < "${config_module_faq_file}"
	log 'Loaded FAQ items'
}

# Called after module has loaded.
# Loads FAQ items
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
	# Only respond in channel.
	[[ $2 =~ ^# ]] || return 0
	local sender="$1"
	local channel="$2"
	local query="$3"
	if [[ "$query" =~ ^${config_listenchar}faq.* ]]; then
		query="${query//${config_listenchar}faq/}"
		query="${query/# /}"
		if [[ "$query" =~ reload ]]; then
			if access_check_owner "$sender"; then
				send_msg "$channel" "Reloading FAQ items..."
				module_faq_load
				send_msg "$channel" "Done."
				sleep 2
			else
				access_fail "$sender" "reload faq items" "owner"
			fi
			return 1
		fi
		local query_time="$(date +%H%M)$line"
		if [[ "$module_faq_last_query" != "$query_time" ]] ; then #must be atleast 1 min old or different query...
			module_faq_last_query="$(date +%H%M)$line"
			if [[ "$query" -gt 0 ]]; then
				log "$channel :$query is numeric"
				send_msg "$channel" "${module_faq_array[$query]}"
				# Very simple way to prevent flooding ourself off.
				sleep 1
			elif [[ "${#query}" -ge 3 ]] ; then
				local i=0
				while [[ $i -lt "${#module_faq_array[*]}" ]] ; do
					i=$((i+1))
					if echo ${module_faq_array[$i]} | cut -d " " -f 3- | /bin/grep -i -F -m 1 "$query" ; then
						log "$channel :${module_faq_array[$i]}"
						send_msg "$channel" "${module_faq_array[$i]}"
						sleep 1
						break 1
					fi
				done
			fi
		else
			log "ERROR : FLOOD DETECTED"
		fi
		return 1
	fi
	return 0
}
