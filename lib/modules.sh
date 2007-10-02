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

# List of loaded modules
modules_loaded=""

# Call from after_load with a list of modules that you depend on
# Parameters
#   $1 What module you are calling from.
#   $2 Space separated list of modules you depend on
# Return codes
#   0 Success
#   1 Other error
#     You should return 1 from after_load.
#   2 One or several of the dependencies could found.
#     You should return 1 from after_load.
#   3 Not all of the dependencies could be loaded (modules exist but did not
#     load correctly).
#     You should return 1 from after_load.
modules_depends_register() {
	local callermodule="$1"
	local dep
	for dep in $2; do
		if [[ $dep == $callermodule ]]; then
			log_error_file modules.log "To the module author of $callermodule: You can't list yourself as a dependency of yourself!"
			log_error_file modules.log "Aborting!"
			return 1
		fi
		if ! list_contains "modules_loaded" "$dep"; then
			log_info_file modules.log "Loading dependency of $callermodule: $dep"
			modules_load "$dep"
			local status="$?"
			if [[ $status -eq 4 ]]; then
				return 2
			elif [[ $status -ne 0 ]]; then
				return 3
			fi
		fi
		if list_contains "modules_depends_${dep}" "$callermodule"; then
			log_warning_file modules.log "Dependency ${callermodule} already listed as depending on ${dep}!?"
		fi
		# HACK: If you find a better way than eval, please tell me!
		eval "modules_depends_${dep}=\"\$modules_depends_${dep} $callermodule\""
	done
}

# Semi internal!
# List modules that depend on another module.
# Parameters
#   $1 Module to check
# Returns on STDOUT
#   List of modules that depend on this.
modules_depends_list_deps() {
	# This is needed to be able to use indirect refs
	local deplistname="modules_depends_${1}"
	misc_clean_spaces "${!deplistname}"
}

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
# See doc/module_api.txt instead                                          #
###########################################################################

# Used by unload to unregister from depends system
# (That is: remove from list of "depended on by" of other modules)
# Parameters
#   $1 Module to unregister
modules_depends_unregister() {
	local module newval
	for module in $modules_loaded; do
		if list_contains "modules_depends_${module}" "$1"; then
			newval="$(list_remove "modules_depends_${module}" "$1")"
			# HACK: If you find a better way than eval, please tell me!
			eval "modules_depends_${module}=\"$newval\""
		fi
	done
}


# Check if a module can be unloaded
# Parameters
#   $1 Name of module to check
# Return status
#   0 Can be unloaded
#   1 Is needed by some other module.
modules_depends_can_unload() {
	# This is needed to be able to use indirect refs
	local deplistname="modules_depends_${1}"
	# Not emtpy/only whitespaces?
	if ! [[ ${!deplistname} =~ ^\ *$ ]]; then
		return 1
	fi
	return 0
}

modules_add_hooks() {
	local module="$1"
	local hooks="$(module_${module}_INIT)"
	[[ $? -ne 0 ]] && { log_error_file modules.log "Failed to get hooks for $module"; return 1; }
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
				log_error_file modules.log "ERROR: Unknown hook $hook requested. Module may malfunction. Module will be unloaded"
				return 1
				;;
		esac
	done
}

# List of all the optional hooks.
modules_hooks="FINALISE after_load before_connect on_connect after_connect before_disconnect after_disconnect on_server_ERROR on_NOTICE on_PRIVMSG on_TOPIC on_channel_MODE on_JOIN on_PART on_KICK on_QUIT on_KILL on_NICK on_numeric on_raw"

# Unload a module
# Parameters
#   $1 Module name
# Return status
#   0 Unloaded
#   2 Module not loaded
#   3 Can't unload, some other module depends on this.
# If the unload fails the bot will quit.
modules_unload() {
	local module="$1"
	local hook newval to_unset
	if ! list_contains "modules_loaded" "$module"; then
		log_warning_file modules.log "No such module as $1 is loaded."
		return 2
	fi
	if ! modules_depends_can_unload "$module"; then
		log_error_file modules.log "Can't unload $module because these module(s) depend(s) on it: $(modules_depends_list_deps "$module")"
		return 3
	fi
	# Remove hooks from list first in case unloading fails so we can do quit hooks if something break.
	for hook in $modules_hooks; do
		# List so we can unset.
		if list_contains "modules_${hook}" "$module"; then
			to_unset="$to_unset module_${module}_${hook}"
		fi
		newval="$(list_remove "modules_${hook}" "$module")"
		# I can't think of a better way :(
		eval "modules_$hook=\"$newval\""
	done
	module_${module}_UNLOAD || {
		log_fatal_file modules.log "Could not unload ${module}, module_${module}_UNLOAD returned ${?}!"
		bot_quit "Fatal error in module unload, please see log"
	}
	unset module_${module}_UNLOAD
	unset module_${module}_INIT
	unset module_${module}_REHASH
	# Unset from list created above.
	for hook in $to_unset; do
		unset "$hook" || {
			log_fatal_file modules.log "Could not unset the hook $hook of module $module!"
			bot_quit "Fatal error in module unload, please see log"
		}
	done
	modules_depends_unregister "$module"
	modules_loaded="$(list_remove "modules_loaded" "$module")"
	return 0
}

# Load a module
# Parameters
#   $1 Name of module to load
# Returns status
#   0 Loaded ok
#   1 Other errors
#   2 Module already loaded
#   3 Failed to source it
#   4 No such module
#   5 Getting hooks failed
#   6 after_load failed
# If the load fails in a fatal way the bot will quit.
modules_load() {
	module="$1"
	if list_contains "modules_loaded" "$module"; then
		log_warning_file modules.log "Module ${module} is already loaded."
		return 2
	fi
	if [[ -f "${config_modules_dir}/m_${module}.sh" ]]; then
		source "${config_modules_dir}/m_${module}.sh"
		if [[ $? -eq 0 ]]; then
			modules_loaded="$modules_loaded $module"
			modules_add_hooks "$module" || \
				{
					log_error_file modules.log "Hooks failed for $module"
					# Try to unload.
					modules_unload "$module" || {
						log_fatal_file modules.log "Failed Unloading of $module (that failed to load)."
						bot_quit "Fatal error in module unload of failed module load, please see log"
					}
					return 5
				}
			if grep -qw "$module" <<< "$modules_after_load"; then
				module_${module}_after_load
				if [[ $? -ne 0 ]]; then
					modules_unload ${module} || {
						log_fatal_file modules.log "Unloading of $module that failed after_load failed."
						bot_quit "Fatal error in module unload of failed module load (after_load), please see log"
					}
					return 6
				fi
			fi
		else
			log_error_file modules.log "Could not load ${module}, failed to source it."
			return 3
		fi
	else
		log_error_file modules.log "No such module as ${module} exists."
		return 4
	fi
}

# Load modules from the config
modules_load_from_config() {
	for module in $config_modules; do
		if [[ -f "${config_modules_dir}/m_${module}.sh" ]]; then
			if ! list_contains modules_loaded "$module"; then
				modules_load "$module"
			fi
		else
			log_warning_file modules.log "$module doesn't exist! Removing it from list"
		fi
	done
}
