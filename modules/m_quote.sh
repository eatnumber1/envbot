#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
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
#---------------------------------------------------------------------
## Quotes module
#---------------------------------------------------------------------

module_quote_INIT() {
	modinit_API='2'
	modinit_HOOKS='after_load'
	commands_register "$1" 'quote' || return 1
}

module_quote_UNLOAD() {
	unset module_quote_load
	unset module_quote_quotes
}

module_quote_REHASH() {
	module_quote_load
}

#---------------------------------------------------------------------
## Load quotes from file
## @Type Private
#---------------------------------------------------------------------
module_quote_load() {
	local i=0 line
	unset module_quote_quotes
	if [[ -z "$config_module_quotes_file" ]]; then
		log_error "quotes module: You need to set config_module_quotes_file in your config!"
		return 1
	elif [[ -r "$config_module_quotes_file" ]]; then
		local IFS=$'\n'
		module_quote_quotes=( $(<"${config_module_quotes_file}") )
		unset IFS
		log_info 'Loaded Quotes.'
		return 0
	else
		log_error "quotes module: Quotes failed to load: Cannot load \"$config_module_quotes_file\". File doesn't exist."
		return 1
	fi
}

module_quote_after_load() {
	# Return code from last command in a function
	# will be return code for the function by default.
	module_quote_load
}

module_quote_handler_quote() {
	local sender="$1"
	local channel="$2"
	# If it isn't in a channel send message back to person who send it,
	# otherwise send in channel
	if ! [[ $2 =~ ^# ]]; then
		parse_hostmask_nick "$sender" 'channel'
	fi
	local number="$RANDOM"
	(( number %= ${#module_quote_quotes[*]} ))
	send_msg "$channel" "${module_quote_quotes[$number]}"
}
