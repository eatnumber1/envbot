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

# Bad name of function, it gets the argument
# after a ":", the last multiword argument
# Only reads FIRST as data
# Returns on STDOUT
# FIXME: Can't handle a ":" in a word before the place to split
parse_get_colon_arg() {
	cut -d':' -f2- <<< "$1"
}

# Returns on STDOUT: nick
# parameter: n!u@h mask
parse_hostmask_nick() {
	cut -d'!' -f1 <<< "$1"
}
