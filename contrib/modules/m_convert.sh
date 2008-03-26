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
## Convert values with units
## @Dependencies This module depends on units
## @Dependencies (http://www.gnu.org/software/units/units.html)
#---------------------------------------------------------------------

module_convert_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	if ! hash units > /dev/null 2>&1; then
		log_error "Couldn't find \"units\" command line tool. The convert module depend on that tool."
		return 1
	fi
	# Is it GNU units?
	if units --help > /dev/null 2>&1; then
		module_convert_gnu=1
	else
		module_convert_gnu=0
	fi
	commands_register "$1" 'convert' || return 1
}

module_convert_UNLOAD() {
	return 0
}

module_convert_REHASH() {
	return 0
}

module_convert_handler_convert() {
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
	# Format: convert <value> <in unit> <out unit>
	if [[ "$parameters" =~ ^([-0-9.]+)\ +([a-zA-Z0-9^/*]+)\ +(to\ +)?([a-zA-Z0-9^/*]+) ]]; then
		local value="${BASH_REMATCH[1]}"
		local inunit="${BASH_REMATCH[2]}"
		local outunit="${BASH_REMATCH[@]: -1}"
		# Construct expression of value and inunit,
		# needed because of temperature
		case $inunit in
			C|F|K)
				# This only work on GNU units.
				if [[ $module_convert_gnu = 1 ]]; then
					local inexpr="temp${inunit}($value)"
				else
					local inexpr="$value deg${inunit}"
				fi
				;;
			*)
				local inexpr="$value $inunit"
				;;
		esac
		# Out: Temperature
		case $outunit in
			C|F|K)
				# This only work on GNU units
				if [[ $module_convert_gnu = 1 ]]; then
					local outexpr="temp${outunit}"
				else
					local outexpr="deg${outunit}"
				fi
				local outunit="degrees $outunit"
				;;
			*)
				local outexpr="$outunit"
				;;
		esac

		# Need to do the local separately or return code will be messed up.
		local myresult
		# Force some security guards
		# We can't use -t, that doesn't work on *BSD units...
		# so we use awk to get interesting lines.
		# Then check pipestatus to give nice return code
		myresult="$(ulimit -t 4; units -q "$inexpr" "$outexpr" 2>&1 | awk '/^\t[0-9]+/ {print $1} /\*/ {print $2} /[Ee]rror|[Uu]nknown/'; [[ ${PIPESTATUS[0]} -eq 0 ]] || exit 1)"
		if [[ $? -eq 0 ]]; then
			send_msg "$channel" "${sendernick}: $myresult $outunit"
		else
			send_msg "$channel" "${sendernick}: Error: $myresult"
		fi
	else
		feedback_bad_syntax "$sendernick" "convert" "<value> <in unit> [to] <out unit>"
	fi
}
