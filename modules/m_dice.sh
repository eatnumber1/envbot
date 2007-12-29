#!/bin/bash
# -*- coding: utf-8 -*-

module_dice_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	commands_register "$1" 'roll' || return 1
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
		local how_much_sides="${BASH_REMATCH[2]}"
		local target=
		if [[ $2 =~ ^# ]]; then
			target="$2"
		else
			parse_hostmask_nick "$sender" 'target'
		fi
		local insane=0
		# Chech if number of dies and sides are sane.
		if (( ($how_much_sides < 2 || $how_much_sides > 100)
			 || ($how_much_times < 1 || $how_much_times > 100) )); then
			 log_warning "Tried to roll $how_much_times dies $how_much_sides each!"
			 log_warning "This is above the allowed maximum or below the allowed minimum, and was aborted."
			 send_msg "$target" "You can't roll that."
			 return 0
		fi
		# Roll $how_much_times dies, each with $how_much_sides sides.
		local result=
		local total=0
		for (( i=0; $i < $how_much_times; i+=1 )); do
			local rolled=$(( ($RANDOM % $how_much_sides) + 1 ))
			result+="$rolled, "
			((total += $rolled))
		done
		send_msg "$target" "You rolled ${result}with the grand total of $total" # $result has the ' ' at the end already
	else
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "roll" "<dies>d<sides>"
	fi
}
