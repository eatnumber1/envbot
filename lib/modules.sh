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

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
# Yes that means the whole file!                                          #
# See doc/module_api.txt instead                                          #
###########################################################################


modules_add_hooks() {
	local module="$1"
	local hooks="$(module_${module}_INIT)"
	local hook
	for hook in $hooks; do
		case $hook in
			"FINALISE")
				modules_FINALISE="$modules_before_connect $module"
				;;
			"after_load")
				modules_after_load="$modules_after_load $module"
				;;
			"before_connect")
				modules_before_connect="$modules_before_connect $module"
				;;
			"on_connect")
				modules_on_connect="$modules_on_connect $module"
				;;
			"after_connect")
				modules_after_connect="$modules_after_connect $module"
				;;
			"before_disconnect")
				modules_before_disconnect="$modules_before_disconnect $module"
				;;
			"after_disconnect")
				modules_after_disconnect="$modules_after_disconnect $module"
				;;
			"on_server_ERROR")
				modules_on_server_ERROR="$modules_on_server_ERROR $module"
				;;
			"on_NOTICE")
				modules_on_NOTICE="$modules_on_NOTICE $module"
				;;
			"on_PRIVMSG")
				modules_on_PRIVMSG="$modules_on_PRIVMSG $module"
				;;
			"on_TOPIC")
				modules_on_TOPIC="$modules_on_TOPIC $module"
				;;
			"on_channel_MODE")
				modules_on_channel_MODE="$modules_on_channel_MODE $module"
				;;
			"on_JOIN")
				modules_on_JOIN="$modules_on_JOIN $module"
				;;
			"on_PART")
				modules_on_PART="$modules_on_PART $module"
				;;
			"on_KICK")
				modules_on_KICK="$modules_on_KICK $module"
				;;
			"on_QUIT")
				modules_on_QUIT="$modules_on_QUIT $module"
				;;
			"on_KILL")
				modules_on_KILL="$modules_on_KILL $module"
				;;
			"on_NICK")
				modules_on_NICK="$modules_on_NICK $module"
				;;
			"on_numeric")
				modules_on_numeric="$modules_on_numeric $module"
				;;
			"on_raw")
				modules_on_raw="$modules_on_raw $module"
				;;
			*)
				log "ERROR: Unknown hook $hook requested. Module may malfunction. Shutting down bot to prevent damage"
				exit 1
				;;
		esac
	done
}

# List of all the optional hooks.
modules_hooks="FINALISE after_load before_connect on_connect after_connect before_disconnect after_disconnect on_server_ERROR on_NOTICE on_PRIVMSG on_TOPIC on_channel_MODE on_JOIN on_PART on_KICK on_QUIT on_KILL on_NICK on_numeric on_raw"


# $1 = module name
# Return: 0 = unloaded
#         2 = Module not loaded
# If the unload fails the bot will quit.
modules_unload() {
	local module="$1"
	local hook newval
	if ! grep -qw "$module" <<< "${modules_loaded}"; then
		log_stdout "No such module as $1 is loaded."
		return 2
	fi
	# Remove hooks from list first in case unloading fails so we an do quit hooks.
	for hook in $modules_hooks; do
		newval="$(list_remove "modules_${hook}" "$module")"
		# I can't think of a better way :(
		eval "modules_$hook=\"$newval\""
	done
	module_${module}_UNLOAD || \
		{ log_stdout "ERROR: Could not unload ${module}, module_${module}_UNLOAD returned ${?}!"; quit_bot; }
	unset module_${module}_UNLOAD
	unset module_${module}_INIT
	unset module_${module}_REHASH
	modules_loaded="$(list_remove "modules_loaded" "$module")"
	return 0
}

# $1 = Name of module to load
# Returns 0 = Loaded ok
#         1 = Other errors
#         2 = Module already loaded
modules_load() {
	module="$1"
	if grep -qw "$module" <<< "${modules_loaded}"; then
		log_stdout "Module $1 is already loaded."
		return 2
	fi
	if [ -f "modules/${module}.sh" ]; then
		source modules/${module}.sh
		if [[ $? -eq 0 ]]; then
			modules_loaded="$modules_loaded $module"
			modules_add_hooks "$module"
			if grep -qw "$module" <<< "$modules_after_load"; then
				module_${module}_after_load
			fi
		fi
	fi
}

modules_loaded=""
# Load modules
modules_load_from_config() {
	for module in $config_modules; do
		if [ -f "modules/${module}.sh" ]; then
			modules_load "$module"
		else
			log "WARNING: $module doesn't exist! Removing it from list"
		fi
	done
}
