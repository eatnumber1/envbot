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
## User feedback.
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## Return a message that syntax was bad and what the correct syntax is.
## @Type API
## @param To who (nick or channel)
## @param From what command
## @param Syntax help
#---------------------------------------------------------------------
feedback_bad_syntax() {
	send_notice "$1" "Syntax error. Correct syntax for $2 is $2 $3"
}

#---------------------------------------------------------------------
## Return a message that something else was wrong in the command.
## @Type API
## @param To who (nick or channel)
## @param From what function
## @param Error message.
#---------------------------------------------------------------------
feedback_generic_error() {
	send_notice "$1" "$2: Error: $3"
}

#---------------------------------------------------------------------
## Return a message that a command was unknown.
## @Type Private
## @param Sender of message (n!u@h)
## @param To where (botnick or channel)
## @param Query
#---------------------------------------------------------------------
feedback_unknown_command() {
	local sendernick
	parse_hostmask_nick "$sender" 'sendernick'
	send_notice "$sendernick" "Error: Not able to parse this command: \"$3\". Are you sure you spelled it correctly?"
}
