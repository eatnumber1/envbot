#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2009  Arvid Norlander                               #
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
## Misc functions.
#---------------------------------------------------------------------


# Some codes for IRC formatting
#---------------------------------------------------------------------
## IRC formatting: Bold
## @Type API
#---------------------------------------------------------------------
format_bold=$'\002'
#---------------------------------------------------------------------
## IRC formatting: Underline
## @Type API
#---------------------------------------------------------------------
format_underline=$'\037'
#---------------------------------------------------------------------
## IRC formatting: Color
## @Type API
#---------------------------------------------------------------------
format_color=$'\003'
#---------------------------------------------------------------------
## IRC formatting: Inverse
## @Type API
#---------------------------------------------------------------------
format_inverse=$'\026'
#---------------------------------------------------------------------
## IRC formatting: Restore to normal
## @Type API
#---------------------------------------------------------------------
format_normal=$'\017'
#---------------------------------------------------------------------
## IRC formatting: ASCII bell
## Please. Don't. Abuse. This.
## @Type API
#---------------------------------------------------------------------
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

#---------------------------------------------------------------------
## This will add colors around this text.
## @Type API
## @param Foreground color
## @param Background color
## @param String to colorise
#---------------------------------------------------------------------
format_colorise() {
	echo "${format_color}${1},${2}${3}${format_normal}"
}

#---------------------------------------------------------------------
## Quits the bot in a graceful way.
## @Type API
## @param Reason to quit (optional)
## @param Return status (optional, if not given, then exit 0).
#---------------------------------------------------------------------
bot_quit() {
	# Yes this function is odd but there is a reason.
	# If this is called from a trap like Ctrl-C we must be able to
	# resume.
	# Keep track of in what state we are
	while true; do
		case "$envbot_quitting" in
			0)
				for module in $modules_before_disconnect; do
					module_${module}_before_disconnect
				done
				(( envbot_quitting++ ))
				;;
			1)
				local reason="$1"
				send_quit "$reason"
				sleep 1
				(( envbot_quitting++ ))
				;;
			2)
				server_connected=0
				for module in $modules_after_disconnect; do
					module_${module}_after_disconnect
				done
				(( envbot_quitting++ ))
				;;
			3)
				for module in $modules_FINALISE; do
					module_${module}_FINALISE
				done
				(( envbot_quitting++ ))
				;;
			4)
				log_info_stdout "Bot quit gracefully"
				transport_disconnect
				(( envbot_quitting++ ))
				;;
			# -1 is before main loop entered,
			# may happen during module loading
			5|-1)
				rm -rvf "$tmp_home"
				if [[ $2 ]]; then
					exit $2
				else
					exit 0
				fi
				;;
			*)
				log_error "Um. bot_quit() and envbot_quitting is $envbot_quitting. This shouldn't happen."
				log_error "Please report a bug including the last 40 lines or so of log and what you did to cause it."
				# Quit and clean up temp files.
				envbot_quit 2
				;;
		esac
	done
}

#---------------------------------------------------------------------
## Restart the bot in a graceful way. I hope.
## @Type API
## @param Reason to restart (optional)
#---------------------------------------------------------------------
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
	exec env -i TERM="$TERM" "$(type -p bash)" $0 "${command_line[@]}"
}


#---------------------------------------------------------------------
## Strip leading/trailing spaces.
## @Type API
## @Note Before this function was deprecated, but it has been recoded
## @Note in a much faster way. This version is not compatible with old
## @Note version.
## @param String to strip
## @param Variable to return in
#---------------------------------------------------------------------
misc_clean_spaces() {
	# Fastest way that is still secure
	local array
	read -ra array <<< "$1"
	printf -v "$2" '%s' "${array[*]}"
}

#---------------------------------------------------------------------
## Strip leading/trailing separator.
## @Type API
## @param String to strip
## @param Variable to return in
## @param Separator
#---------------------------------------------------------------------
misc_clean_delimiter() {
	local sep="$3" array
	local IFS="$sep"
	# Fastest way that is still secure
	read -ra array <<< "$1"
	local tmp="${array[*]}"
	printf -v "$2" '%s' "${tmp#${sep}}"
}

#---------------------------------------------------------------------
## Remove a value from a space (or other delimiter) separated list.
## @Type API
## @param List to remove from.
## @param Value to remove.
## @param Variable to return new list in.
## @param Separator (optional, defaults to space)
#---------------------------------------------------------------------
list_remove() {
	local sep=${4:-" "}
	local oldlist="${sep}${!1}${sep}"
	local newlist="${oldlist//${sep}${2}${sep}/${sep}}"
	misc_clean_delimiter "$newlist" "$3" "$sep" # Get rid of the unneeded spaces.
}

#---------------------------------------------------------------------
## Checks if a space separated list contains a value.
## @Type API
## @param List to check.
## @param Value to check for.
## @return 0 If found.
## @return 1 If not found.
#---------------------------------------------------------------------
list_contains() {
	[[ " ${!1} " = *" $2 "* ]]
}

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

#---------------------------------------------------------------------
## Like debug_assert_argc but works without debugging on.
## For use in sensitive functions in core.
## @Type Private
## @param Minimum count of parameters
## @param Maximum count of parameters
## @param All the rest of the parameters as "$@"
## @Example For example this could be called as:
## @Example <pre>
## @Example foo() {
## @Example   security_assert_argc 2 2 "$@"
## @Example   ... rest of function ...
## @Example }
## @Example </pre>
#---------------------------------------------------------------------
security_assert_argc() {
	local min="$1" max="$2"
	shift 2
	if [[ $# -lt $min || $# -gt $max ]]; then
		log_error "Security sensitive function ${FUNCNAME[1]} should have had between $min and $max parameters but had $# instead."
		log_error "Security sensitive function ${FUNCNAME[1]} was called from ${BASH_SOURCE[2]}:${BASH_LINENO[1]} ${FUNCNAME[2]} with these parameters: $*"
		log_error "This should be reported as a bug."
		return 1
	fi
	return 0
}
