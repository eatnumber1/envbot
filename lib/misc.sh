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

# Some codes for IRC formatting
format_bold=$'\002'
format_underline=$'\037'
format_color=$'\003'
format_inverse=$'\026'
format_normal=$'\017'
# Please. Don't. Abuse. This.
format_bell=$'\007'

# Color table:
# white         0
# black         1
# blue          2
# green         3
# red           4
# darkred       5
# purple        6
# darkyellow    7
# yellow        8
# brightgreen   9
# darkaqua      10
# aqua          11
# lightblue     12
# brightpurple  13
# darkgrey      14
# lightgrey     15

# This will add colors around this text.
# Parameters
#   $1 Foreground color
#   $2 Background color
#   $3 String to colorise
format_colorise() {
	echo "${format_color}${1},${2}${3}${format_normal}"
}

# Quits the bot in a graceful way.
# Parameters
#   $1 Reason to quit (optional)
#   $2 Return status (optional, if not given, then exit 0).
bot_quit() {
	for module in $modules_before_disconnect; do
		module_${module}_before_disconnect
	done
	local reason="$1"
	send_quit "$reason"
	sleep 1
	server_connected=0
	for module in $modules_after_disconnect; do
		module_${module}_after_disconnect
	done
	for module in $modules_FINALISE; do
		module_${module}_FINALISE
	done
	log_info_stdout "Bot quit gracefully"
	transport_disconnect
	rm -rvf "$tmp_home"
	if [[ $2 ]]; then
		exit $2
	else
		exit 0
	fi
}

# Restart the bot in a graceful way. I hope.
# Parameters
#   $1 Reason to restart (optional)
bot_restart() {
	for module in $modules_before_disconnect; do
		module_${module}_before_disconnect
	done
	local reason="$1"
	send_quit "$reason"
	sleep 1
	server_connected=0
	for module in $modules_after_disconnect; do
		module_${module}_after_disconnect
	done
	for module in $modules_FINALISE; do
		module_${module}_FINALISE
	done
	log_info_stdout "Bot quit gracefully"
	transport_disconnect
	rm -rvf "$tmp_home"
	exec env -i "$(type -p bash)" $0 "${command_line[@]}"
}


# Check if a set time has passed
# Parameters
#   $1 Unix timestamp to check against
#   $2 Number of seconds
# Return code
#   0 If at least the given number of seconds has passed
#   1 If it hasn't
time_check_interval() {
	local newtime="$(date -u +%s)"
	(( ( $newtime - $1 ) > $2 ))
}


# Strip leading/trailing spaces.
# Parameters
#   $1 String to strip
# Returns on STDOUT
#   New string
misc_clean_spaces() {
	# Fastest way that is still secure
	local array
	read -ra array <<< "$1"
	echo "${array[*]}"
}

# Remove a value from a space separated list.
# Parameters
#   $1 List to remove from.
#   $2 Value to remove.
# Returns on STDOUT
#   New list
list_remove() {
	local oldlist="${!1}"
	local newlist="${oldlist//$2}"
	misc_clean_spaces "$newlist" # Get rid of the unneeded spaces.
}

# Checks if a space separated list contains a value.
# Parameters
#   $1 List to check.
#   $2 Value to check for.
# Return code
#   0 If found.
#   1 If not found.
list_contains() {
	grep -Fwq "$2" <<< "${!1}"
}
