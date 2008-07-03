#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2008  Arvid Norlander                               #
#  Copyright (C) 2007-2008  Vsevolod Kozlov                               #
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
## Rolls dies.
#---------------------------------------------------------------------

module_dice_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	commands_register "$1" 'roll' || return 1
	helpentry_module_dice_description="Rolls dies for you."

	helpentry_dice_roll_syntax="<dies>d<sides>"
	helpentry_dice_roll_description="Rolls <dies> dies, each <sides> sides."
}

module_dice_UNLOAD() {
	return 0
}

module_dice_REHASH() {
	return 0
}

module_dice_handler_roll() {
	local sender="$1"
	local parameters="$3"
	if [[ $parameters =~ ^([0-9]+)d([0-9]+)$ ]]; then
		local how_much_times="${BASH_REMATCH[1]}"
		local how_many_sides="${BASH_REMATCH[2]}"
		local target=
		if [[ $2 =~ ^# ]]; then
			target="$2"
		else
			parse_hostmask_nick "$sender" 'target'
		fi
		local insane=0
		# Chech if number of dies and sides are sane.
		if (( ($how_many_sides < 2 || $how_many_sides > 100)
			 || ($how_much_times < 1 || $how_much_times > 100) )); then
			 log_warning "Tried to roll $how_much_times dies $how_many_sides sides each!"
			 log_warning "This is above the allowed maximum or below the allowed minimum, and was aborted."
			 send_msg "$target" "You can't roll that."
			 return 0
		fi
		# Roll $how_much_times dies, each with $how_many_sides sides.
		local result=""
		local total=0
		for (( i=0; $i < $how_much_times; i+=1 )); do
			local rolled=$(( ($RANDOM % $how_many_sides) + 1 ))
			result+="$rolled, "
			((total += $rolled))
		done
		result=${result%, }
		if [[ $how_much_times != 1 ]]; then
			result+=" with the grand total of $total"
		fi
		send_msg "$target" "You rolled ${result}."
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "roll" "<dies>d<sides>"
	fi
}
