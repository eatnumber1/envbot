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
## Modules management
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## List of loaded modules. Don't change from other code.
## @Type Semi-private
#---------------------------------------------------------------------
modules_loaded=""

#---------------------------------------------------------------------
## Current module API version.
#---------------------------------------------------------------------
declare -r modules_current_API=2


#---------------------------------------------------------------------
## Call from after_load with a list of modules that you depend on
## @Type API
## @param What module you are calling from.
## @param Space separated list of modules you depend on
## @return 0 Success
## @return 1 Other error. You should return 1 from after_load.
## @return 2 One or several of the dependencies could found. You should return 1 from after_load.
## @return 3 Not all of the dependencies could be loaded (modules exist but did not load correctly). You should return 1 from after_load.
#---------------------------------------------------------------------
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
		# Use printf not eval here.
		local listname="modules_depends_${dep}"
		printf -v "modules_depends_${dep}" '%s' "${!listname} $callermodule"
	done
}

#---------------------------------------------------------------------
## Call from after_load or INIT with a list of modules that you
## depend on optionally.
## @Type API
## @param What module you are calling from.
## @param The module you want to depend on optionally.
## @return 0 Success, module loaded
## @return 1 User didn't list it as loaded, don't use the features in question
## @return 2 Other error. You should return 1 from after_load.
## @return 3 One or several of the dependencies could found. You should return 1 from after_load.
## @return 4 Not all of the dependencies could be loaded (modules exist but did not load correctly). You should return 1 from after_load.
#---------------------------------------------------------------------
modules_depends_register_optional() {
	local callermodule="$1"
	local dep="$2"
	if ! list_contains "modules_loaded" "$dep"; then
		# So not loaded, now we need to find out if we should load it or not
		# We use $config_modules for it
		if ! list_contains 'config_modules' "$dep"; then
			log_info_file modules.log "Optional dependency of $callermodule ($dep) not loaded."
			return 1
		fi
		log_info_file modules.log "Loading optional dependency of $callermodule: ($dep)"
	fi
	# Ah we should load it then? Call modules_depends_register
	modules_depends_register "$@"
}


#---------------------------------------------------------------------
## Semi internal!
## List modules that depend on another module.
## @Type Semi-private
## @param Module to check
## @Stdout List of modules that depend on this.
#---------------------------------------------------------------------
modules_depends_list_deps() {
	# This is needed to be able to use indirect refs
	local deplistname="modules_depends_${1}"
	# Clean out spaces, fastest way
	echo ${!deplistname}
}

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
# See doc/module_api.txt instead                                          #
###########################################################################

#---------------------------------------------------------------------
## Used by unload to unregister from depends system
## (That is: remove from list of "depended on by" of other modules)
## @Type Private
## @param Module to unregister
#---------------------------------------------------------------------
modules_depends_unregister() {
	local module newval
	for module in $modules_loaded; do
		if list_contains "modules_depends_${module}" "$1"; then
			list_remove "modules_depends_${module}" "$1" "modules_depends_${module}"
		fi
	done
}

#---------------------------------------------------------------------
## Check if a module can be unloaded
## @Type Private
## @param Name of module to check
## @return Can be unloaded
## @return Is needed by some other module.
#---------------------------------------------------------------------
modules_depends_can_unload() {
	# This is needed to be able to use indirect refs
	local deplistname="modules_depends_${1}"
	# Not empty/only whitespaces?
	if ! [[ ${!deplistname} =~ ^\ *$ ]]; then
		return 1
	fi
	return 0
}

#---------------------------------------------------------------------
## Add hooks for a module
## @Type Private
## @param Module name
## @param MODULE_BASE_PATH, exported to INIT as a part of the API
## @return 0 Success
## @return 1 module_modulename_INIT returned non-zero
## @return 2 Module wanted to register an unknown hook.
#---------------------------------------------------------------------
modules_add_hooks() {
	local module="$1"
	local modinit_HOOKS
	local modinit_API
	local MODULE_BASE_PATH="$2"
	module_${module}_INIT "$module"
	[[ $? -ne 0 ]] && { log_error_file modules.log "Failed to get initialize module \"$module\""; return 1; }
	# Check if it didn't set any modinit_API, in that case it is a API 1 module.
	if [[ -z $modinit_API ]]; then
		log_warning "Please upgrade \"$module\" to new module API $modules_current_API. This old API is deprecated."
		modinit_HOOKS="$(module_${module}_INIT)"
	elif [[ $modinit_API -ne $modules_current_API ]]; then
		log_error "Current module API version is $modules_current_API, but the API version of \"$module\" is $module_API."
		return 1
	fi

	local hook
	for hook in $modinit_HOOKS; do
		case $hook in
			"FINALISE")
				modules_FINALISE+=" $module"
				;;
			"after_load")
				modules_after_load+=" $module"
				;;
			"before_connect")
				modules_before_connect+=" $module"
				;;
			"on_connect")
				modules_on_connect+=" $module"
				;;
			"after_connect")
				modules_after_connect+=" $module"
				;;
			"before_disconnect")
				modules_before_disconnect+=" $module"
				;;
			"after_disconnect")
				modules_after_disconnect+=" $module"
				;;
			"periodic")
				modules_periodic+=" $module"
				;;
			"on_module_UNLOAD")
				modules_on_module_UNLOAD+=" $module"
				;;
			"on_server_ERROR")
				modules_on_server_ERROR+=" $module"
				;;
			"on_NOTICE")
				modules_on_NOTICE+=" $module"
				;;
			"on_PRIVMSG")
				modules_on_PRIVMSG+=" $module"
				;;
			"on_TOPIC")
				modules_on_TOPIC+=" $module"
				;;
			"on_channel_MODE")
				modules_on_channel_MODE+=" $module"
				;;
			"on_user_MODE")
				modules_on_user_MODE+=" $module"
				;;
			"on_INVITE")
				modules_on_INVITE+=" $module"
				;;
			"on_JOIN")
				modules_on_JOIN+=" $module"
				;;
			"on_PART")
				modules_on_PART+=" $module"
				;;
			"on_KICK")
				modules_on_KICK+=" $module"
				;;
			"on_QUIT")
				modules_on_QUIT+=" $module"
				;;
			"on_KILL")
				modules_on_KILL+=" $module"
				;;
			"on_NICK")
				modules_on_NICK+=" $module"
				;;
			"on_numeric")
				modules_on_numeric+=" $module"
				;;
			"on_PONG")
				modules_on_PONG+=" $module"
				;;
			"on_raw")
				modules_on_raw+=" $module"
				;;
			*)
				log_error_file modules.log "Unknown hook $hook requested. Module may malfunction. Module will be unloaded"
				return 2
				;;
		esac
	done
}

#---------------------------------------------------------------------
## List of all the optional hooks.
## @Type Private
#---------------------------------------------------------------------
modules_hooks="FINALISE after_load before_connect on_connect after_connect before_disconnect after_disconnect periodic on_module_UNLOAD on_server_ERROR on_NOTICE on_PRIVMSG on_TOPIC on_channel_MODE on_user_MODE on_INVITE on_JOIN on_PART on_KICK on_QUIT on_KILL on_NICK on_numeric on_PONG on_raw"

#---------------------------------------------------------------------
## Unload a module
## @Type Private
## @param Module name
## @return 0 Unloaded
## @return 2 Module not loaded
## @return 3 Can't unload, some other module depends on this.
## @Note If the unload fails for other reasons the bot will quit.
#---------------------------------------------------------------------
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
			to_unset+=" module_${module}_${hook}"
		fi
		list_remove "modules_${hook}" "$module" "modules_${hook}"
	done
	commands_unregister "$module" || {
		log_fatal_file modules.log "Could not unregister commands for ${module}"
		bot_quit "Fatal error in module unload, please see log"
	}
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
	list_remove "modules_loaded" "$module" "modules_loaded"

	# Call any hooks for unloading modules.
	local othermodule
	for othermodule in $modules_on_module_UNLOAD; do
		module_${othermodule}_on_module_UNLOAD "$module"
	done

	return 0
}

#---------------------------------------------------------------------
## Generate awk script to validate module functions.
## @param Module name
## @Type Private
## @return 0 If the file is OK
## @return 1 If the file lacks one of more of the functions.
#---------------------------------------------------------------------
modules_check_function() {
	local module="$1"
	# This is a one liner. Well mostly. ;)
	# We check that the needed functions exist.
	awk "function check_found() { if (init && unload && rehash) exit 0 }
	/^declare -f module_${module}_INIT$/   { init=1; check_found() }
	/^declare -f module_${module}_UNLOAD$/ { unload=1; check_found() }
	/^declare -f module_${module}_REHASH$/ { rehash=1; check_found() }
	END { if (! (init && unload && rehash)) exit 1 }"
}

#---------------------------------------------------------------------
## Load a module
## @Type Private
## @param Name of module to load
## @return 0 Loaded Ok
## @return 1 Other errors
## @return 2 Module already loaded
## @return 3 Failed to source it in safe subshell
## @return 4 Failed to source it
## @return 5 No such module
## @return 6 Getting hooks failed
## @return 7 after_load failed
## @Note If the load fails in a fatal way the bot will quit.
#---------------------------------------------------------------------
modules_load() {
	local module="$1"
	if list_contains "modules_loaded" "$module"; then
		log_warning_file modules.log "Module ${module} is already loaded."
		return 2
	fi
	# modulebase is exported as MODULE_BASE_PATH
	# with ${config_modules_dir} prepended to the
	# INIT function, useful for multi-file
	# modules, but available for other modules too.
	local modulefilename modulebase
	if [[ -f "${config_modules_dir}/m_${module}.sh" ]]; then
		modulefilename="m_${module}.sh"
		modulebase="${modulefilename}"
	elif [[ -d "${config_modules_dir}/m_${module}" && -f "${config_modules_dir}/m_${module}/__main__.sh" ]]; then
		modulefilename="m_${module}/__main__.sh"
		modulebase="m_${module}"
	else
		log_error_file modules.log "No such module as ${module} exists."
		return 5
	fi
	( source "${config_modules_dir}/${modulefilename}" )
	if [[ $? -ne 0 ]]; then
		log_error_file modules.log "Could not load ${module}, failed to source it in safe subshell."
		return 3
	fi
	( source "${config_modules_dir}/${modulefilename}" && declare -F ) | modules_check_function "$module"
	if [[ $? -ne 0 ]]; then
		log_error_file modules.log "Could not load ${module}, it lacks some important functions it should have."
		return 3
	fi
	source "${config_modules_dir}/${modulefilename}"
	if [[ $? -eq 0 ]]; then
		modules_loaded+=" $module"
		modules_add_hooks "$module" "${config_modules_dir}/${modulebase}" || \
			{
				log_error_file modules.log "Hooks failed for $module"
				# Try to unload.
				modules_unload "$module" || {
					log_fatal_file modules.log "Failed Unloading of $module (that failed to load)."
					bot_quit "Fatal error in module unload of failed module load, please see log"
				}
				return 6
			}
		if grep -qw "$module" <<< "$modules_after_load"; then
			module_${module}_after_load
			if [[ $? -ne 0 ]]; then
				modules_unload ${module} || {
					log_fatal_file modules.log "Unloading of $module that failed after_load failed."
					bot_quit "Fatal error in module unload of failed module load (after_load), please see log"
				}
				return 7
			fi
		fi
	else
		log_error_file modules.log "Could not load ${module}, failed to source it."
		return 4
	fi
}

#---------------------------------------------------------------------
## Load modules from the config
## @Type Private
#---------------------------------------------------------------------
modules_load_from_config() {
	local module
	IFS=" "
	for module in $modules_loaded; do
		if ! list_contains config_modules "$module"; then
			modules_unload "$module"
		fi
	done
	unset IFS
	for module in $config_modules; do
		if [[ -f "${config_modules_dir}/m_${module}.sh" || -d "${config_modules_dir}/m_${module}" ]]; then
			if ! list_contains modules_loaded "$module"; then
				modules_load "$module"
			fi
		else
			log_warning_file modules.log "$module doesn't exist! Removing it from list"
		fi
	done
}
