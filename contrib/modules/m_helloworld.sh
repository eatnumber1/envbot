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
## Example module meant to help people who want to make modules for envbot
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## This is called to get a list of hooks that the module provides.
## Use the hook after_load to do other things
## @Type   Module hook
## @Stdout A list of hooks.
#---------------------------------------------------------------------
module_helloworld_INIT() {
	modinit_API='2'
	# Set modinit_HOOKS to the hooks we have.
	modinit_HOOKS='after_load'
	# Register commands, each command handler will have a name like:
	# module_modulename_handler_function
	# Example: module_helloworld_handler_hi
	# If command name and function name are the same you can skip
	# command name.
	commands_register "$1" 'hi' || return 1
	# Here the function name and command name can't be the same,
	# as the command name got space in it. Note that a command can
	# be at most two words.
	commands_register "$1" 'hello_world' 'hello world' || return 1
	helpentry_module_helloworld_description="This is an example module."

	helpentry_helloworld_hi_syntax='<target> <message>'
	helpentry_helloworld_hi_description='Send a greeting to <target> (nick or channel) with the <message>.'

	helpentry_helloworld_helloworld_syntax='<message>'
	helpentry_helloworld_helloworld_description='Send a greeting to the current scope with the one word <message>.'
}

#---------------------------------------------------------------------
## Here we do anything needed to unload the module.
## @Type   Module hook
## @return 0 Unloaded correctly
## @return 1 Failed to unload. On this the bot will quit.
## @Note   This function is NOT called when the bot is exiting. To check for that
## @Note   use the FINALISE hook!
#---------------------------------------------------------------------
module_helloworld_UNLOAD() {
	# Here we unset any functions and variables that we have defined
	# except the hook functions.
	unset module_helloworld_variable module_helloworld_function
}

#---------------------------------------------------------------------
## Here do anything needed at rehash
## @Type   Module hook
## @return 0 Rehashed correctly
## @return 1 Non fatal error for the bot itself. The bot will call UNLOAD on the module.
## @return 2 Fatal error of some kind. On this the bot will quit.
#---------------------------------------------------------------------
module_helloworld_REHASH() {
	# We don't have anything to do here.
	return 0
}

#---------------------------------------------------------------------
## Called after all the hooks are added for the module.
## @Type   Module hook
## @return 0 Unloaded correctly
## @return 1 Failed. On this the bot will call unload on the module.
#---------------------------------------------------------------------
module_helloworld_after_load() {
	# Set a global variable, this can't be done in INIT.
	# Remember to unset all global variables on UNLOAD!
	module_helloworld_variable="world!"
}

#---------------------------------------------------------------------
## This logs "hello world" as an informative level log item
## when called
## @Type Private
## @Note Note that this is a custom function used by
## @Note some other part of the script
#---------------------------------------------------------------------
module_helloworld_function() {
	# Lets use the variable defined above!
	log_info "Hello $module_helloworld_variable"
}

#---------------------------------------------------------------------
## Called on the command "hello world"
## @Type  Function handler
## @param From who (n!u@h)
## @param To who (channel or botnick)
## @param The parameters to the command
#---------------------------------------------------------------------
module_helloworld_handler_hello_world() {
	local sender="$1"
	local target
	# If it isn't in a channel send message back to person who send it,
	# otherwise send in channel
	if [[ $2 =~ ^# ]]; then
		target="$2"
	else
		# parse_hostmask_nick gets the nick from a hostmask.
		parse_hostmask_nick "$sender" 'target'
	fi

	local parameters="$3"
	# Check if the syntax for the parameters is correct!
	# Lets check for one parameter without spaces
	if [[ "$parameters" =~ ^([^ ]+) ]]; then
		# Store the bit in the first group of the regex into
		# the variable message
		local message="${BASH_REMATCH[1]}"
		# Send a hello world message:
		send_msg "$target" "Hello world! I had the parameter $message"
	else
		# So the regex for matching parameters didn't work, lets provide
		# the user with some feedback!
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "hello world" "<message> # Where message is one word!"
	fi
}

#---------------------------------------------------------------------
## Called on the command "hi"
## @Type  Function handler
## @param From who (n!u@h)
## @param To who (channel or botnick)
## @param The parameters to the command
#---------------------------------------------------------------------
module_helloworld_handler_hi() {
	local sender="$1"

	local parameters="$3"
	# Two parameters, one is single word, the other matches to
	# end of line.
	if [[ "$parameters" =~ ^([^ ]+)\ (.+) ]]; then
		# Store the groups in some variables.
		local target_channel="${BASH_REMATCH[1]}"
		local message="${BASH_REMATCH[2]}"
		# This is used for the access check below.
		# Check if target is a channel or nick.
		local scope
		if [[ $target_channel =~ ^# ]]; then
			scope="$target_channel"
		else
			scope="MSG"
		fi

		# Lets check for access.
		# First variable is capability to check for
		# Second variable is the hostmask of the sender of the message
		# Third variable is the scope, that we set above.
		if access_check_capab "hi" "$sender" "$scope"; then
			# Such important events for security as a "hi" should
			# really get logged even if it fails! ;)
			access_log_action "$sender" "made the hi channel \"$message\" in/to \"$target_channel\""
			local sendernick
			parse_hostmask_nick "$sender" 'sendernick'
			send_msg "${target_channel}" "Hi $target_channel! $sendernick wants you to know ${message}"
			# As an example also call our function.
			module_helloworld_function
		else
			# Lets tell the sender they lack access!
			# access_fail will send a PRIVMSG to the sender saying permission denied
			# and also log the failed attempt.
			access_fail "$sender" "make the bot hi" "hi"
		fi
	else
		# As above, provide feedback about bad syntax.
		local sendernick
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "hi" "<target> <message> # Where target is a nick or channel"
	fi
}
