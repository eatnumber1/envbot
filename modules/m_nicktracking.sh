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
## Provides nick tracking API for other modules.
#---------------------------------------------------------------------

module_nicktracking_INIT() {
	echo 'after_load before_connect on_numeric on_NICK on_QUIT on_KICK on_PART on_JOIN'
}

module_nicktracking_UNLOAD() {
	unset module_nicktracking_channels
	hash_reset module_nicktracking_channels_nicks
	hash_reset module_nicktracking_nicks
	# Private functions
	unset module_nicktracking_clear_nick module_nicktracking_clear_chan
	unset module_nicktracking_parse_names
	# API functions
	unset module_nicktracking_get_hostmask_by_nick
	unset module_nicktracking_get_channel_nicks
	return 0
}

module_nicktracking_REHASH() {
	return 0
}

module_nicktracking_after_load() {
	# Handle case of loading while bot is running
	if [[ $server_connected -eq 1 ]]; then
		module_nicktracking_channels="$channels_current"
		local channel
		for channel in $module_nicktracking_channels; do
			send_raw "NAMES $channel"
			# We have to send a WHO #channel if servers doesn't support UHNAMES.
			if [[ $server_UHNAMES -eq 0 ]]; then
				send_raw "WHO $2"
			fi
		done
	fi
}

module_nicktracking_before_connect() {
	# Reset state.
	unset module_nicktracking_channels
	hash_reset module_nicktracking_channels_nicks
	hash_reset module_nicktracking_nicks
	return 0
}

#---------------------------------------------------------------------
## Return hostmask of a nick
## @Type API
## @param Nick to find hostmask for
## @param Variable to return hostmask in
## @Note If no nick is found (or data about the nick
## @Note is missing currently), the return variable will be empty.
#---------------------------------------------------------------------
module_nicktracking_get_hostmask_by_nick() {
	hash_get 'module_nicktracking_nicks' "$1" "$2"
}

#---------------------------------------------------------------------
## Return list of nicks on a channel
## @Type API
## @param Channel to check
## @param Variable to return space separated list in
## @return 0 Channel data exists.
## @return 1 We don't track this channel.
#---------------------------------------------------------------------
module_nicktracking_get_channel_nicks() {
	if list_contains 'module_nicktracking_channels' "$1"; then
		hash_get 'module_nicktracking_channels_nicks' "$1" "$2"
		return 0
	else
		return 1
	fi
}

#---------------------------------------------------------------------
## Check if a nick should be removed
## @Type Private
## @param Nick to check
#---------------------------------------------------------------------
module_nicktracking_clear_nick() {
	# If not on a channel any more, remove knowledge about nick.
	if ! hash_search 'module_nicktracking_channels_nicks' "$1"; then
		hash_unset 'module_nicktracking_nicks' "$1"
	fi
}

#---------------------------------------------------------------------
## Clear a channel (if we part it or such)
## @Type Private
## @param Channel name
#---------------------------------------------------------------------
module_nicktracking_clear_chan() {
	list_remove 'module_nicktracking_channels' "$1" 'module_nicktracking_channels'
	# Get list and then unset it.
	local nicks=
	hash_get 'module_nicktracking_channels_nicks' "$1" 'nicks'
	hash_unset 'module_nicktracking_channels_nicks' "$1"
	# Sigh, this isn't fast I know...
	local nick
	for nick in $nicks; do
		module_nicktracking_clear_nick "$nick"
	done
}

#---------------------------------------------------------------------
## Parse RPL_NAMREPLY data.
## @Type Private
## @param NAMES data
#---------------------------------------------------------------------
module_nicktracking_parse_names() {
	if [[ $1 =~ ^[=*@]?\ *(#[^ ]+)\ +:(.+) ]]; then
		local channel="${BASH_REMATCH[1]}"
		local nicks="${BASH_REMATCH[2]}"
		local entry nick realnick
		# Loop through the entries
		for entry in $nicks; do
			# This will work both with and without NAMESX
			if [[ $entry =~ [$server_PREFIX_prefixes]*([^ ]+) ]]; then
				nick="${BASH_REMATCH[1]}"
				# Is UHNAMES enabled?
				# If yes lets take care of hostmask.
				if [[ $server_UHNAMES -eq 1 ]]; then
					parse_hostmask_nick "$nick" 'realnick'
					hash_set 'module_nicktracking_nicks' "$realnick" "$nick"
					# Add to nick list of channel
					hash_append 'module_nicktracking_channels_nicks' "$channel" "$realnick"
				else
					# Add to nick list of channel
					hash_append 'module_nicktracking_channels_nicks' "$channel" "$nick"
				fi
			else
				log_error_file unknown_data.log "module_nicktracking_parse_names: Uh uh, regex for inner loop is bad, couldn't parse: $nick"
				log_error_file unknown_data.log "module_nicktracking_parse_names: Please report a bug with the above message"
			fi
		done
	else
		log_error_file unknown_data.log "module_nicktracking_parse_names: Uh uh, outer regex is bad, couldn't parse: $1"
		log_error_file unknown_data.log "module_nicktracking_parse_names: Please report a bug with the above message"
	fi
	return 0
}


##########################
# Message handling hooks #
##########################

module_nicktracking_on_numeric() {
	case $1 in
		"$numeric_RPL_NAMREPLY")
			# TODO: Parse NAMES
			module_nicktracking_parse_names "$2"
			;;
	esac
}

module_nicktracking_on_NICK() {
	local oldnick oldident oldhost oldentry
	parse_hostmask "$1" 'oldnick' 'oldident' 'oldhost'
	# Remove old and add new.
	hash_get 'module_nicktracking_nicks' "$oldnick" 'oldentry'
	hash_unset 'module_nicktracking_nicks' "$oldnick"
	hash_set 'module_nicktracking_nicks' "$2" "${2}!${oldident}@${oldhost}"
	local channel
	# Loop through the channels
	for channel in $module_nicktracking_channels; do
		hash_replace 'module_nicktracking_channels_nicks' "$channel" "$oldnick" "$2"
	done
	return 0
}

module_nicktracking_on_QUIT() {
	local whoquit=
	parse_hostmask_nick "$1" 'whoquit'
	hash_unset 'module_nicktracking_nicks' "$whoquit"
	local channel
	# Remove from channel
	for channel in $module_nicktracking_channels; do
		hash_substract 'module_nicktracking_channels_nicks' "$channel" "$whoquit"
	done
	return 0
}

module_nicktracking_on_KICK() {
	local whogotkicked="$3"
	if [[ $whogotkicked == $server_nick_current ]]; then
		module_nicktracking_clear_chan "$2"
	else
		hash_substract 'module_nicktracking_channels_nicks' "$2" "$whogotkicked"
	fi
	# If not on a channel any more, remove knowledge about nick.
	module_nicktracking_clear_nick "$whogotkicked"
}

module_nicktracking_on_PART() {
	# Check if it was us
	local whoparted=
	parse_hostmask_nick "$1" 'whoparted'
	if [[ $whoparted == $server_nick_current ]]; then
		module_nicktracking_clear_chan "$2"
	else
		hash_substract 'module_nicktracking_channels_nicks' "$2" "$whoparted"
	fi
	# If not on a channel any more, remove knowledge about nick.
	module_nicktracking_clear_nick "$whoparted"
	return 0
}

module_nicktracking_on_JOIN() {
	local whojoined=
	parse_hostmask_nick "$1" 'whojoined'
	if [[ $whojoined == $server_nick_current ]]; then
		module_nicktracking_channels+=" $2"
		hash_set 'module_nicktracking_channels_nicks' "$2" "$server_nick_current"
		# We have to send a WHO #channel if servers doesn't support UHNAMES.
		if [[ $server_UHNAMES -eq 0 ]]; then
			send_raw "WHO $2"
		fi
	else
		hash_append 'module_nicktracking_channels_nicks' "$2" "$whojoined"
	fi
	hash_set 'module_nicktracking_nicks' "$whojoined" "$1"
	return 0
}
