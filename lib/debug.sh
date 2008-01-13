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
## Functions used during development for debugging.
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## Debugging function to check that right number of parameters were
## provided.
## @param Lowest allowed count of parameters.
## @param Higest allowed count of parameters. (Optional, defaults to same as lower)
#---------------------------------------------------------------------
debug_assert_argc() {
	[[ $envbot_debugging ]] || return 0
	if [[ ${BASH_ARGC[1]} -lt $1 || ${BASH_ARGC[1]} -gt ${2:-$1} ]]; then
		log_debug "${FUNCNAME[1]} should have had $1 parameters but had ${BASH_ARGC[1]} instead"
		log_debug "${FUNCNAME[1]} was called from ${BASH_SOURCE[2]}:${BASH_LINENO[1]} ${FUNCNAME[2]}."
		return 1
	fi
}

#---------------------------------------------------------------------
## Reports who called function and with what arguments.
## @Type API
## @param Should be "$@" at first line of function.
#---------------------------------------------------------------------
debug_log_caller() {
	[[ $envbot_debugging ]] || return 0
	log_debug "${FUNCNAME[1]} called from ${BASH_SOURCE[2]}:${BASH_LINENO[1]} ${FUNCNAME[2]} with arguments: $*"
}

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

#---------------------------------------------------------------------
## Enable debugging.
## @Type Private
#---------------------------------------------------------------------
debug_enable() {
	envbot_debugging=1
	shopt -s extdebug
	log_debug "Debugging enabled"
}

#---------------------------------------------------------------------
## Disable debugging.
## @Type Private
#---------------------------------------------------------------------
debug_disable() {
	envbot_debugging=''
	shopt -u extdebug
	log_debug "Debugging disabled"
}

#---------------------------------------------------------------------
## Enable or disable debugging at startup.
## @Type Private
#---------------------------------------------------------------------
debug_init() {
	if [[ "$envbot_debugging" ]]; then
		debug_enable
	fi
}
