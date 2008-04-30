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
## Simple Vote module
#---------------------------------------------------------------------

# Note on module_vote_votes_count
# Format for entries are:
# For Against Abstain

module_vote_INIT() {
	modinit_API='2'
	if [[ -z "$config_module_vote_channel" ]]; then
		log_error "vote module: You need to set config_module_vote_channel in your config!"
		return 1
	fi
	if [[ -z "$config_module_vote_timeout" ]]; then
		log_error "vote module: You need to set config_module_vote_timeout in your config!"
		return 1
	fi
	modinit_HOOKS='periodic'
	commands_register "$1" 'PROPOSE' || return 1
	commands_register "$1" 'FOR' || return 1
	commands_register "$1" 'AGAINST' || return 1
	commands_register "$1" 'ABSTAIN' || return 1
	commands_register "$1" 'LIST' || return 1
	commands_register "$1" 'INFO' || return 1
}

module_vote_UNLOAD() {
	hash_reset module_vote_descs
	hash_reset module_vote_votes
	hash_reset module_vote_submitter
	hash_reset module_vote_timestamps
	hash_reset module_vote_votes_count
	hash_reset module_vote_votes_for
	hash_reset module_vote_votes_against
	hash_reset module_vote_votes_abstain
	unset module_vote_array_names

	unset module_vote_add_proposal
	unset module_vote_votes_count
}

module_vote_REHASH() {
	:
}



module_vote_periodic() {
	# Check if we got some proposals to process
	local propname index exptime
	for index in ${!module_vote_array_names[*]}; do
		propname="${module_vote_array_names[${index}]}"
		hash_get module_vote_timestamps "$propname" 'exptime'
		if [[ $envbot_time -gt "$exptime" ]]; then
			local votes desc
			module_vote_votes_count "$propname" 'votes'
			hash_get module_vote_descs "$propname" 'desc'
			send_msg "${config_module_vote_channel}" "$votename closes with $votes:"
			send_msg "${config_module_vote_channel}" "$desc"
			hash_unset module_vote_timestamps     "$votename"
			hash_unset module_vote_submitter      "$votename"
			hash_unset module_vote_descs          "$votename"
			hash_unset module_vote_votes_count    "$votename"
			hash_unset module_vote_votes_for      "$votename"
			hash_unset module_vote_votes_against  "$votename"
			hash_unset module_vote_votes_abstain  "$votename"
			unset "module_vote_array_names[${index}]"
		fi
	done
}


# $1 Name
# $2 timestamp
# $3 Submitter
# $4 Text
module_vote_add_proposal() {
	module_vote_array_names+=("$1")
	hash_set module_vote_timestamps     "$1" "$2"
	hash_set module_vote_submitter      "$1" "$3"
	hash_set module_vote_descs          "$1" "$4"
	hash_set module_vote_votes_count    "$1" "1 0 0"
	hash_set module_vote_votes_for      "$1" "$3"
	hash_set module_vote_votes_against  "$1" ""
	hash_set module_vote_votes_abstain  "$1" ""
}

# $1 Name
# $2 Outvariable (formatted)
module_vote_votes_count() {
	local vEntry
	local vTotal vFor vAgainst vAbstain
	hash_get module_vote_votes_count "$1" 'vEntry'
	IFS=" " read -r vFor vAgainst vAbstain <<< "${vEntry}"
	printf -v "$2" "FOR: %s AGAINST: %s ABSTAIN: %s" "$vFor" "$vAgainst" "$vAbstain"
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_vote_handler_PROPOSE() {
	local sender="$1"
	local channel="$2"
	local sendernick
	parse_hostmask_nick "$sender" 'sendernick'
	# If it isn't in a channel reject it
	if ! [[ $2 =~ ^${config_module_vote_channel}$ ]]; then
		send_msg "$sendernick" "This must be done in the channel ${config_module_vote_channel}."
		return
	fi
	if [[ "$3" =~ ^([a-zA-Z0-9][-_a-zA-Z0-9]+)\ (.+)$ ]]; then
		local propname="${BASH_REMATCH[1]}"
		local proptext="${BASH_REMATCH[2]}"
		if [[ " ${module_vote_array_names[*]} " = *" $propname "* ]]; then
			send_msg "${config_module_vote_channel}" "A proposal called $propname already exists."
		else
			local exptime
			time_get_current 'exptime'
			(( exptime += $config_module_vote_timeout ))
			send_msg "$channel" "Created proposal $propname: $proptext"
			module_vote_add_proposal "$propname" "$exptime" "$sendernick" "$proptext"
		fi
	else
		feedback_bad_syntax "$sendernick" "PROPOSE" "<proposal name> <text of proposal>"
	fi
}


module_vote_handler_FOR() {
	local sender="$1"
	local channel="$2"
	local sendernick
	parse_hostmask_nick "$sender" 'sendernick'
	# If it isn't in a channel reject it
	if ! [[ $2 =~ ^${config_module_vote_channel}$ ]]; then
		send_msg "$sendernick" "This must be done in the channel ${config_module_vote_channel}."
		return
	fi

	if [[ "$3" =~ ^([a-zA-Z0-9][-_a-zA-Z0-9]+)$ ]]; then
		local propname="${BASH_REMATCH[1]}"
		if [[ " ${module_vote_array_names[*]} " = *" $propname "* ]]; then
			local exptime
			hash_get module_vote_timestamps "$propname" 'exptime'
			if [[ $envbot_time -gt "$exptime" ]]; then
				send_msg "${config_module_vote_channel}" "$sendernick: Sorry, too late, proposal just closed."
			else
				local vEntry vFor vAgainst vAbstain
				hash_get module_vote_votes_count "$propname" 'vEntry'
				IFS=" " read -r vFor vAgainst vAbstain <<< "${vEntry}"
				if ! hash_contains module_vote_votes_for "$propname" "$sendernick"; then
					hash_append module_vote_votes_for "$propname" "$sendernick"
					(( vFor++ ))
				fi
				if hash_contains module_vote_votes_against "$propname" "$sendernick"; then
					hash_substract module_vote_votes_against "$propname" "$sendernick"
					(( vAgainst-- ))
				fi
				if hash_contains module_vote_votes_abstain "$propname" "$sendernick"; then
					hash_substract module_vote_votes_abstain "$propname" "$sendernick"
					(( vAbstain-- ))
				fi
				hash_set module_vote_votes_count "$propname" "$vFor $vAgainst $vAbstain"
				send_msg "${config_module_vote_channel}" "$sendernick: Done"
			fi
		else
			send_msg "${config_module_vote_channel}" "That proposal doesn't exist."
		fi
	else
		feedback_bad_syntax "$sendernick" "FOR" "<proposal name>"
	fi
}

module_vote_handler_AGAINST() {
	local sender="$1"
	local channel="$2"
	local sendernick
	parse_hostmask_nick "$sender" 'sendernick'
	# If it isn't in a channel reject it
	if ! [[ $2 =~ ^${config_module_vote_channel}$ ]]; then
		send_msg "$sendernick" "This must be done in the channel ${config_module_vote_channel}."
		return
	fi

	if [[ "$3" =~ ^([a-zA-Z0-9][-_a-zA-Z0-9]+)$ ]]; then
		local propname="${BASH_REMATCH[1]}"
		if [[ " ${module_vote_array_names[*]} " = *" $propname "* ]]; then
			local exptime
			hash_get module_vote_timestamps "$propname" 'exptime'
			if [[ $envbot_time -gt "$exptime" ]]; then
				send_msg "${config_module_vote_channel}" "$sendernick: Sorry, too late, proposal just closed."
			else
				local vEntry vFor vAgainst vAbstain
				hash_get module_vote_votes_count "$propname" 'vEntry'
				IFS=" " read -r vFor vAgainst vAbstain <<< "${vEntry}"
				if hash_contains module_vote_votes_for "$propname" "$sendernick"; then
					hash_substract module_vote_votes_for "$propname" "$sendernick"
					(( vFor-- ))
				fi
				if ! hash_contains module_vote_votes_against "$propname" "$sendernick"; then
					hash_append module_vote_votes_against "$propname" "$sendernick"
					(( vAgainst++ ))
				fi
				if hash_contains module_vote_votes_abstain "$propname" "$sendernick"; then
					hash_substract module_vote_votes_abstain "$propname" "$sendernick"
					(( vAbstain-- ))
				fi
				hash_set module_vote_votes_count "$propname" "$vFor $vAgainst $vAbstain"
				send_msg "${config_module_vote_channel}" "$sendernick: Done"
			fi
		else
			send_msg "${config_module_vote_channel}" "That proposal doesn't exist."
		fi
	else
		feedback_bad_syntax "$sendernick" "AGAINST" "<proposal name>"
	fi
}


module_vote_handler_ABSTAIN() {
	local sender="$1"
	local channel="$2"
	local sendernick
	parse_hostmask_nick "$sender" 'sendernick'
	# If it isn't in a channel reject it
	if ! [[ $2 =~ ^${config_module_vote_channel}$ ]]; then
		send_msg "$sendernick" "This must be done in the channel ${config_module_vote_channel}."
		return
	fi

	if [[ "$3" =~ ^([a-zA-Z0-9][-_a-zA-Z0-9]+)$ ]]; then
		local propname="${BASH_REMATCH[1]}"
		if [[ " ${module_vote_array_names[*]} " = *" $propname "* ]]; then
			local exptime
			hash_get module_vote_timestamps "$propname" 'exptime'
			if [[ $envbot_time -gt "$exptime" ]]; then
				send_msg "${config_module_vote_channel}" "$sendernick: Sorry, too late, proposal just closed."
			else
				local vEntry vFor vAgainst vAbstain
				hash_get module_vote_votes_count "$propname" 'vEntry'
				IFS=" " read -r vFor vAgainst vAbstain <<< "${vEntry}"
				if hash_contains module_vote_votes_for "$propname" "$sendernick"; then
					hash_substract module_vote_votes_for "$propname" "$sendernick"
					(( vFor-- ))
				fi
				if hash_contains module_vote_votes_against "$propname" "$sendernick"; then
					hash_substract module_vote_votes_against "$propname" "$sendernick"
					(( vAgainst-- ))
				fi
				if ! hash_contains module_vote_votes_abstain "$propname" "$sendernick"; then
					hash_append module_vote_votes_abstain "$propname" "$sendernick"
					(( vAbstain++ ))
				fi
				hash_set module_vote_votes_count "$propname" "$vFor $vAgainst $vAbstain"
				send_msg "${config_module_vote_channel}" "$sendernick: Done"
			fi
		else
			send_msg "${config_module_vote_channel}" "That proposal doesn't exist."
		fi
	else
		feedback_bad_syntax "$sendernick" "ABSTAIN" "<proposal name>"
	fi
}

module_vote_handler_LIST() {
	local sender="$1"
	local channel="$2"
	local sendernick
	parse_hostmask_nick "$sender" 'sendernick'
	# If it isn't in a channel reject it
	if ! [[ $2 =~ ^${config_module_vote_channel}$ ]]; then
		send_msg "$sendernick" "This must be done in the channel ${config_module_vote_channel}."
		return
	fi
	if [[ -z "${module_vote_array_names[*]}" ]]; then
		send_msg "${config_module_vote_channel}" "No proposals exist."
	else
		local votename exptime submitter diff votes
		for votename in "${module_vote_array_names[@]}"; do
			hash_get module_vote_timestamps "$votename" 'exptime'
			time_format_difference $(( $exptime - $envbot_time )) 'diff'
			hash_get module_vote_submitter "$votename" 'submitter'
			module_vote_votes_count "$votename" 'votes'
			send_msg "${config_module_vote_channel}" "$votename (by $submitter) closes in $diff ($votes)"
		done
	fi
}

module_vote_handler_INFO() {
	local sender="$1"
	local channel="$2"
	local sendernick
	parse_hostmask_nick "$sender" 'sendernick'
	# If it isn't in a channel reject it
	if ! [[ $2 =~ ^${config_module_vote_channel}$ ]]; then
		send_msg "$sendernick" "This must be done in the channel ${config_module_vote_channel}."
		return
	fi
	if [[ "$3" =~ ^([a-zA-Z0-9][-_a-zA-Z0-9]+)$ ]]; then
		local propname="${BASH_REMATCH[1]}"
		if [[ " ${module_vote_array_names[*]} " = *" $propname "* ]]; then
			local exptime desc submitter diff votes
			hash_get module_vote_timestamps "$propname" 'exptime'
			time_format_difference $(( $exptime - $envbot_time )) 'diff'
			hash_get module_vote_descs "$propname" 'desc'
			hash_get module_vote_submitter "$propname" 'submitter'
			module_vote_votes_count "$propname" 'votes'
			send_msg "${config_module_vote_channel}" "$propname (by $submitter) closes in $diff ($votes)"
			send_msg "${config_module_vote_channel}" "Description: $desc"
		else
			send_msg "${config_module_vote_channel}" "That proposal doesn't exist."
		fi
	else
		feedback_bad_syntax "$sendernick" "INFO" "<proposal name>"
	fi
}
