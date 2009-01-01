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
## This is the main file, it should be called with a wrapper (envbot)
#---------------------------------------------------------------------


###################
#                 #
#  Sanity checks  #
#                 #
###################

# Error to fail with for old bash.
fail_old_bash() {
	echo "Sorry your bash version is too old!"
	echo "You need at least version 3.2.10 of bash"
	echo "Please install a newer version:"
	echo " * Either use your distro's packages"
	echo " * Or see http://www.gnu.org/software/bash/"
	exit 2
}

# Check bash version. We need at least 3.2.10
# Lets not use anything like =~ here because
# that may not work on old bash versions.
if [[ "${BASH_VERSINFO[0]}${BASH_VERSINFO[1]}" -lt 32 ]]; then
	fail_old_bash
elif [[ "${BASH_VERSINFO[0]}${BASH_VERSINFO[1]}" -eq 32 && "${BASH_VERSINFO[2]}" -lt 10 ]]; then
	fail_old_bash
fi

# We should not run as root.
if [[ $EUID -eq 0 ]]; then
	echo "ERROR: Don't run envbot as root. Please run it under a normal user. Really."
	exit 1
fi

######################
#                    #
#  Set up variables  #
#                    #
######################

# Version and URL
#---------------------------------------------------------------------
## Version of envbot.
## @Type API
## @Read_only Yes
#---------------------------------------------------------------------
declare -r envbot_version='0.1-trunk+bzr'
#---------------------------------------------------------------------
## Homepage of envbot.
## @Type API
## @Read_only Yes
#---------------------------------------------------------------------
declare -r envbot_homepage='http://envbot.org'

##############
#            #
#  Sane env  #
#            #
##############

# Set some variables to make bot work sane
# For example tr + some LC_COLLATE = breaks in some cases.
unset LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY
unset LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS
unset LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION
export LC_ALL=C
export LANG=C

# Some of these may be overkill, but better be on
# safe side.
set +amu
set -f
shopt -u sourcepath hostcomplete progcomp xpg_echo dotglob
shopt -u nocasematch nocaseglob nullglob
shopt -s extquote promptvars extglob

# If you need some other PATH, override in top of config...
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# To make set -x more usable
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]} : '


# This is needed when we run the bot with env -i as recommended.
declare -r tmp_home="$(mktemp -dt envbot.home.XXXXXXXXXX)"
# I don't want to end up with rm -rf $HOME in case it is something
# else at that point, so lets use another variable.

# Temp trap on ctrl-c until the next "stage" of trap gets loaded (at connect)
trap 'rm -rvf "$tmp_home"; exit 1' TERM INT

#---------------------------------------------------------------------
## Now create a temp function to quit on problems in a way that cleans up
## temp stuff until we have loaded enough to use the normal function bot_quit.
## @param Return status of bot
#---------------------------------------------------------------------
envbot_quit() {
	rm -rf "$tmp_home"
	exit "$1"
}

# And finally lets export this as $HOME
export HOME="$tmp_home"

#---------------------------------------------------------------------
## Will be set to 1 if -v or --verbose is passed
## on command line.
## @Type Private
#---------------------------------------------------------------------
force_verbose=0

#---------------------------------------------------------------------
## Store command line for later use
## @Type Private
#---------------------------------------------------------------------
command_line=( "$@" )

#---------------------------------------------------------------------
## Current config version.
## @Type API
## @Read_only Yes
#---------------------------------------------------------------------
declare -r config_current_version=17

# Some constants used in different places

#---------------------------------------------------------------------
## Transport modules will wait $envbot_transport_timeout seconds
## before returning control to main loop (to allow periodic events).
## @Type API
## @Read_only Yes
#---------------------------------------------------------------------
declare -r envbot_transport_timeout=5

#---------------------------------------------------------------------
## In progress of quitting? This is used to
## work around the issue in bug 25.<br />
## -1 means not even in main loop yet.
## @Type Private
#---------------------------------------------------------------------
envbot_quitting=-1

#---------------------------------------------------------------------
## If empty debugging is turned off. If not empty it is on.
#---------------------------------------------------------------------
envbot_debugging=''

#---------------------------------------------------------------------
## Print help message
## @Type Private
#---------------------------------------------------------------------
print_cmd_help() {
	echo 'envbot is an advanced modular IRC bot coded in bash.'
	echo ''
	echo 'Usage: envbot [OPTION]...'
	echo ''
	echo 'Options:'
	echo '  -c, --config file       Use file instead of the default as config file.'
	echo '  -l, --libdir directory  Use directory instead of the default as library directory.'
	echo '  -v, --verbose           Force verbose output even if config_log_stdout is 0.'
	echo '  -d, --debug             Enable debugging code. Most likely pointless to anyone'
	echo '                          except envbot developers or module developers.'
	echo '  -h, --help              Display this help and exit'
	echo '  -V, --version           Output version information and exit'
	echo ''
	echo "Note that envbot can't handle short versions of options being written together like"
	echo "-vv currently."
	echo ''
	echo 'Exit status is 0 if OK, 1 if minor problems, 2 if serious trouble.'
	echo ''
	echo 'Examples:'
	echo '  envbot                  Runs envbot with default options.'
	echo '  envbot -c bot.config    Runs envbot with the config bot.config.'
	echo ''
	echo "Report bugs to ${envbot_homepage}/trac/simpleticket"
	envbot_quit 0
}

#---------------------------------------------------------------------
## Print version message
## @Type Private
#---------------------------------------------------------------------
print_version() {
	echo "envbot $envbot_version - An advanced modular IRC bot in bash."
	echo ''
	echo 'Copyright (C) 2007-2009 Arvid Norlander'
	echo 'Copyright (C) 2007-2008 EmErgE'
	echo 'This is free software; see the source for copying conditions.  There is NO'
	echo 'warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.'
	echo ''
	echo 'Written by Arvid Norlander and EmErgE.'
	envbot_quit 0
}

# Parse any command line arguments.
if [[ $# -gt 0 ]]; then
	while [[ $# -gt 0 ]]; do
		case "$1" in
			'--help'|'-help'|'--usage'|'-usage'|'-h')
				print_cmd_help
				;;
			'--config'|'-c')
				config_file="$2"
				shift 2
				;;
			'--debug'|'-d')
				envbot_debugging=1
				shift 1
				;;
			'--libdir'|'-l')
				library_dir="$2"
				shift 2
				;;
			'--verbose'|'-v')
				force_verbose=1
				shift 1
				;;
			'--version'|'-V')
				print_version
				;;
			*)
				print_cmd_help
				;;
		esac
	done
fi

echo "Loading... Please wait"

if [[ -z "$config_file" ]]; then
	echo "ERROR: No config file set, you probably didn't use the wrapper program to start envbot"
	envbot_quit 1
fi

if [[ ! -r "$config_file" ]]; then
	echo "ERROR: Can't read config file ${config_file}."
	echo "Check that it is really there and correct permissions are set."
	echo "If you used --config to specify name of config file, check that you spelled it correctly."
	envbot_quit 1
fi

echo "Loading config"
source "$config_file"
if [[ $? -ne 0 ]]; then
	echo "Error: couldn't load config from $config_file"
	envbot_quit 1
fi

# This is hackish, it should be in config.sh (config_validate)
# The reason is that we need to check some things before we can load config.sh
if [[ -z "$config_version" ]]; then
	echo "ERROR: YOU MUST SET THE CORRECT config_version IN THE CONFIG"
	envbot_quit 2
fi
if [[ $config_version -ne $config_current_version ]]; then
	echo "ERROR: YOUR config_version IS $config_version BUT THE BOT'S CONFIG VERSION IS $config_current_version."
	echo "PLEASE UPDATE YOUR CONFIG. Check bot_settings.sh.example for current format."
	envbot_quit 2
fi

# Force verbose output if -v or --verbose was on
# command line.
if [[ $force_verbose -eq 1 ]]; then
	config_log_stdout='1'
fi

# Must be checked here and not in validate_config because of
# loading order.
if [[ -z "$library_dir" ]]; then
	echo "ERROR: No library directory set, you probably didn't use the wrapper program to start envbot"
	envbot_quit 1
fi

if [[ ! -d "$library_dir" ]]; then
	echo "ERROR: library directory $library_dir does not exist, is not a directory or can't be read for some other reason."
	echo "Check that it is really there and correct permissions are set."
	echo "If you used --libdir to specify location of library directory, check that you spelled it correctly."
	envbot_quit 2
fi

echo "Loading library functions"
# Load library functions.
libraries="hash time log send feedback numerics channels parse \
           access misc config commands modules server debug"
for library in $libraries; do
	source "${library_dir}/${library}.sh"
done
unset library

# Validate other config variables.
config_validate
time_init
log_init
debug_init

log_info_stdout "Loading transport"
source "${config_transport_dir}/${config_transport}.sh"
if [[ $? -ne 0 ]]; then
	log_fatal "Couldn't load transport. Couldn't load the file..."
	envbot_quit 2
fi

if ! transport_check_support; then
	log_fatal "The transport reported it can't work on this system or with this configuration."
	log_fatal "Please read any other errors displayed above and consult documentation for the transport module you are using."
	envbot_quit 2
fi

# Now logging functions can be used.

# Load modules

log_info_stdout "Loading modules"
# Load modules
modules_load_from_config

#---------------------------------------------------------------------
## Used for periodic events later below
## @Type Private
#---------------------------------------------------------------------
periodic_lastrun=''
time_get_current 'periodic_lastrun'
#---------------------------------------------------------------------
## This can be used when the code does not need exact time.
## It will be updated each time the bot get a new line of
## data.
## @Type API
#---------------------------------------------------------------------
envbot_time=''
server_connected_before=0
while true; do
	# In progress of quitting? This is used to
	# work around the issue in bug 25.
	envbot_quitting=0
	for module in $modules_before_connect; do
		module_${module}_before_connect
	done

	if [[ $server_connected_before -ne 0 ]]; then
		# We got here by being connected before and
		# loosing connection, keep retrying
		while true; do
			if server_connect; then
				server_connected_before=1
				break
			else
				log_error "Failed to reconnect, trying again in 20 seconds"
				sleep 20
			fi
		done
	else
		# In this case abort on failure to connect, likely bad config.
		# and most likely the user is present to fix it.
		# If someone disagrees I may change it.
		server_connect || {
			log_error "Connection failed"
			envbot_quit 1
		}
		server_connected_before=1
	fi
	trap 'bot_quit "Interrupted (Ctrl-C)"' INT
	trap 'bot_quit "Terminated (SIGTERM)"' TERM
	for module in $modules_after_connect; do
		module_${module}_after_connect
	done

	while true; do
		line=
		transport_read_line
		transport_status="$?"
		# Still connected?
		if ! transport_alive; then
			break
		fi
		time_get_current 'envbot_time'
		# Time to run periodic events again?
		# We run them every $envbot_transport_timeout second.
		if time_check_interval "$periodic_lastrun" "$envbot_transport_timeout"; then
			time_get_current 'periodic_lastrun'
			envbot_time="$periodic_lastrun"
			for module in $modules_periodic; do
				module_${module}_periodic "${periodic_lastrun}"
			done
		fi
		# Did we timeout waiting for data
		# or did we get data?
		if [[ $transport_status -ne 0 ]]; then
			continue
		fi

		log_raw_in "$line"
		for module in $modules_on_raw; do
			module_${module}_on_raw "$line"
			if [[ $? -ne 0 ]]; then
				# TODO: Check that this does what it should.
				continue 2
			fi
		done
		if [[ $line =~ ^:${server_name}\ +([0-9]{3})\ +([^ ]+)\ +(.*) ]]; then
			# this is a numeric
			numeric="${BASH_REMATCH[1]}"
			numericdata="${BASH_REMATCH[3]}"
			server_handle_numerics "$numeric" "${BASH_REMATCH[2]}" "$numericdata"
			for module in $modules_on_numeric; do
				module_${module}_on_numeric "$numeric" "$numericdata"
				if [[ $? -ne 0 ]]; then
					break
				fi
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +PRIVMSG\ +([^:]+)\ +:(.*) ]]; then
			sender="${BASH_REMATCH[1]}"
			target="${BASH_REMATCH[2]}"
			query="${BASH_REMATCH[3]}"
			# Check if there is a command.
			commands_call_command "$sender" "$target" "$query"
			# Check return code
			case $? in
				1)
					continue
					;;
				2)
					if [[ $config_feedback_unknown_commands -eq 0 ]]; then
						continue
					elif [[ $config_feedback_unknown_commands -eq 1 ]]; then
						feedback_unknown_command "$sender" "$target" "$query"
					fi
					;;
			esac
			for module in $modules_on_PRIVMSG; do
				module_${module}_on_PRIVMSG "$sender" "$target" "$query"
				if [[ $? -ne 0 ]]; then
					break
				fi
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +NOTICE\ +([^:]+)\ +:(.*) ]]; then
			sender="${BASH_REMATCH[1]}"
			target="${BASH_REMATCH[2]}"
			query="${BASH_REMATCH[3]}"
			for module in $modules_on_NOTICE; do
				module_${module}_on_PRIVMSG "$sender" "$target" "$query"
				if [[ $? -ne 0 ]]; then
					break
				fi
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +TOPIC\ +(#[^ ]+)(\ +:(.*))? ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			topic="${BASH_REMATCH[4]}"
			for module in $modules_on_TOPIC; do
				module_${module}_on_TOPIC "$sender" "$channel" "$topic"
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +MODE\ +(#[^ ]+)\ +(.+) ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			modes="${BASH_REMATCH[3]}"
			for module in $modules_on_channel_MODE ; do
				module_${module}_on_channel_MODE "$sender" "$channel" "$modes"
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +MODE\ +([^# ]+)\ +(.+) ]]; then
			sender="${BASH_REMATCH[1]}"
			target="${BASH_REMATCH[2]}"
			modes="${BASH_REMATCH[3]}"
			for module in $modules_on_user_MODE ; do
				module_${module}_on_user_MODE "$sender" "$target" "$modes"
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +INVITE\ +([^ ]+)\ +:?(.+) ]]; then
			sender="${BASH_REMATCH[1]}"
			target="${BASH_REMATCH[2]}"
			channel="${BASH_REMATCH[3]}"
			for module in $modules_on_INVITE; do
				module_${module}_on_INVITE "$sender" "$target" "$channel"
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +NICK\ +:?(.+) ]]; then
			sender="${BASH_REMATCH[1]}"
			newnick="${BASH_REMATCH[2]}"
			# Check if it was our own nick
			server_handle_nick "$sender" "$newnick"
			for module in $modules_on_NICK; do
				module_${module}_on_NICK "$sender" "$newnick"
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +JOIN\ +:?(.*) ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			# Check if it was our own nick that joined
			channels_handle_join "$sender" "$channel"
			for module in $modules_on_JOIN; do
				module_${module}_on_JOIN "$sender" "$channel"
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +PART\ +(#[^ ]+)(\ +:(.*))? ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			reason="${BASH_REMATCH[4]}"
			# Check if it was our own nick that parted
			channels_handle_part "$sender" "$channel" "$reason"
			for module in $modules_on_PART; do
				module_${module}_on_PART "$sender" "$channel" "$reason"
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +KICK\ +(#[^ ]+)\ +([^ ]+)(\ +:(.*))? ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			kicked="${BASH_REMATCH[3]}"
			reason="${BASH_REMATCH[5]}"
			# Check if it was our own nick that got kicked
			channels_handle_kick "$sender" "$channel" "$kicked" "$reason"
			for module in $modules_on_KICK; do
				module_${module}_on_KICK "$sender" "$channel" "$kicked" "$reason"
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +QUIT(\ +:(.*))? ]]; then
			sender="${BASH_REMATCH[1]}"
			reason="${BASH_REMATCH[3]}"
			for module in $modules_on_QUIT; do
				module_${module}_on_QUIT "$sender" "$reason"
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +KILL\ +([^ ]*)\ +:([^ ]*)\ +\((.*)\) ]]; then
			sender="${BASH_REMATCH[1]}"
			target="${BASH_REMATCH[2]}"
			path="${BASH_REMATCH[3]}"
			reason="${BASH_REMATCH[4]}"
			# I don't think we need to check if we were the target or not,
			# the bot doesn't need to care as far as I can see.
			for module in $modules_on_KILL; do
				module_${module}_on_KILL "$sender" "$target" "$path" "$reason"
			done
		elif [[ "$line" =~ ^:([^ ]*)\ +PONG\ +([^ ]*)\ +:?(.*)$ ]]; then
				sender="${BASH_REMATCH[1]}"
				server2="${BASH_REMATCH[2]}"
				data="${BASH_REMATCH[3]}"
				for module in $modules_on_PONG; do
					module_${module}_on_PONG "$sender" "$server2" "$data"
				done
		elif [[ $line =~ ^[^:] ]] ;then
			# ERROR?
			if [[ "$line" =~ ^ERROR\ +:(.*) ]]; then
				error="${BASH_REMATCH[1]}"
				log_error "Got ERROR from server: $error"
				for module in $modules_on_server_ERROR; do
					module_${module}_on_server_ERROR "$error"
				done
				# If we get an ERROR we can assume we are disconnected.
				break
			# PING? If not report as unhandled
			elif ! server_handle_ping "$line"; then
				log_info_file unknown_data.log "A non-sender prefixed line that didn't match any hook: $line"
			fi
		else
			log_info_file unknown_data.log "Something that didn't match any hook: $line"
		fi
	done
	if [[ $envbot_quitting -ne 0 ]]; then
		# Hm, a trap got aborted it seems.
		# Trying to handle this.
		log_info "Quit trap got aborted: envbot_quitting=${envbot_quitting}. Recovering"
		bot_quit
		break
	fi
	log_error 'DIED FOR SOME REASON'
	transport_disconnect
	server_connected=0
	for module in $modules_after_disconnect; do
		module_${module}_after_disconnect
	done
	# Don't reconnect right away. We might get throttled and other nasty stuff.
	sleep 10
done
rm -rf "$tmp_home"
