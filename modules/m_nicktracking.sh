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
## Provides nick <-> channel tracking API for other modules.
#---------------------------------------------------------------------

module_nicktracking_INIT() {
	echo 'after_load before_connect on_numeric on_NICK on_QUIT on_KICK on_PART on_JOIN'
}

module_nicktracking_UNLOAD() {
	unset module_nicktracking_channels
	hash_reset module_nicktracking_channels_nicks
	hash_reset module_nicktracking_nicks
	unset module_nicktracking_clear_nick module_nicktracking_clear_chan
	return 0
}

module_nicktracking_REHASH() {
	return 0
}

module_nicktracking_after_load() {
	return 0
}

module_nicktracking_before_connect() {
	# Reset state.
	unset module_nicktracking_channels
	hash_reset module_nicktracking_channels_nicks
	hash_reset module_nicktracking_nicks
	return 0
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
	# = #envbot :@ChanServ!ChanServ@services.kuonet-ng.org @AnMaster!AnMaster@staff.kuonet-ng.org kon!kon@cloaked-2211A67C.dclient.hispeed.ch envbot!rfc3092@envbot.the.modular.irc.bot.in.bash.that.supports.ipv6.and.ssl @EmErgE!EmErgE@newyork.fbi.gov Coder!coder@B1FF9A2D.818E2F8B.896994A5.IP
	if [[ $1 =~ ^=\ +(#[^ ]+)\ +:(.+) ]]; then
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
				log_error "module_nicktracking_parse_names: Uh uh, regex for inner loop is bad, couldn't parse: $nick"
				log_error "module_nicktracking_parse_names: Please report a bug with the above message"
			fi
		done
	else
		log_error "module_nicktracking_parse_names: Uh uh, regex is bad, couldn't parse: $1"
		log_error "module_nicktracking_parse_names: Please report a bug with the above message"
	fi
	return 0
}


module_nicktracking_on_numeric() {
	case $1 in
		"$numeric_RPL_NAMREPLY")
			# TODO: Parse NAMES
			module_nicktracking_parse_names "$2"
			;;
	esac
}

module_nicktracking_on_NICK() {
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
		hash_substract 'module_nicktracking_channels_nicks' "$2" "$whojoined"
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
	else
		hash_append 'module_nicktracking_channels_nicks' "$2" "$whojoined"
	fi
	hash_set 'module_nicktracking_nicks' "$whojoined" "$1"
	return 0
}
