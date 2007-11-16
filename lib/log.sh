#!/bin/bash
# -*- coding: utf-8 -*-
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
#---------------------------------------------------------------------
## Logging API
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## Log a fatal error to the main log file as well as STDOUT.
## @Type API
## @param The log message to log
#---------------------------------------------------------------------
log_fatal() {
	log "FATAL    " "$log_color_fatal" "$1" 1
}

#---------------------------------------------------------------------
## Log a fatal error to a specific log file as well as
## the main log file and STDOUT.
## @Type API
## @param The extra log file (relative to the current log dir)
## @param The log message to log
#---------------------------------------------------------------------
log_fatal_file() {
	log "FATAL    " "$log_color_fatal" "$2" 1 "$1"
}


#---------------------------------------------------------------------
## Log an error to the main log file as well as STDOUT.
## @Type API
## @param The log message to log
#---------------------------------------------------------------------
log_error() {
	log "ERROR    " "$log_color_error" "$1" 1
}

#---------------------------------------------------------------------
## Log an error to a specific log file as well as
## the main log file and STDOUT.
## @Type API
## @param The extra log file (relative to the current log dir)
## @param The log message to log
#---------------------------------------------------------------------
log_error_file() {
	log "ERROR    " "$log_color_error" "$2" 1 "$1"
}


#---------------------------------------------------------------------
## Log a warning to the main log file as well as STDOUT.
## @Type API
## @param The log message to log
#---------------------------------------------------------------------
log_warning() {
	log "WARNING  " "$log_color_warning" "$1" 1
}

#---------------------------------------------------------------------
## Log a warning to a specific log file as well as
## the main log file and STDOUT.
## @Type API
## @param The extra log file (relative to the current log dir)
## @param The log message to log
#---------------------------------------------------------------------
log_warning_file() {
	log "WARNING  " "$log_color_warning" "$2" 1 "$1"
}


#---------------------------------------------------------------------
## Log an info message to the main log file.
## @Type API
## @param The log message to log
#---------------------------------------------------------------------
log_info() {
	log "INFO     " "$log_color_info" "$1" 0
}

#---------------------------------------------------------------------
## Log an info message to the main log file and STDOUT.
## Normally this shouldn't be used by modules.
## It is used for things like "Connecting"
## @Type API
## @param The log message to log
#---------------------------------------------------------------------
log_info_stdout() {
	log "INFO     " "$log_color_info" "$1" 1
}

#---------------------------------------------------------------------
## Log an info message to a specific log file as well as
## the main log file and STDOUT.
## Normally this shouldn't be used by modules.
## It is used for things like "Connecting"
## @Type API
## @param The extra log file (relative to the current log dir)
## @param The log message to log
#---------------------------------------------------------------------
log_info_stdout_file() {
	log "INFO     " "$log_color_info" "$2" 1 "$1"
}

#---------------------------------------------------------------------
## Log an info message to a specific log file as well as STDOUT.
## @Type API
## @param The extra log file (relative to the current log dir)
## @param The log message to log
#---------------------------------------------------------------------
log_info_file() {
	log "INFO     " "$log_color_info" "$2" 0 "$1"
}

#---------------------------------------------------------------------
## Log a debug message.
## @Type API
## @param The log message to log
#---------------------------------------------------------------------
log_debug() {
	log "DEBUG    " "" "$1" 0 debug.log
}

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

#---------------------------------------------------------------------
## Logging prefix
## @Type Private
#---------------------------------------------------------------------
log_prefix="-"

#---------------------------------------------------------------------
## Get human readable date.
## @Type Private
## @Stdout Human readable date
#---------------------------------------------------------------------
log_get_date() {
	date +'%Y-%m-%d %k:%M:%S'
}

#---------------------------------------------------------------------
## Get escape codes from tput
## @Type Private
## @param capname
## @param Return variable name
## @return 0 OK
## @return 1 Not supported or unknown cap
## @Note Return variable will be unset if the value is not supported
#---------------------------------------------------------------------
log_check_cap() {
	tput $1 >/dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		printf -v "$2" '%s' "$(tput $1)"
	else
		printf -v "$2" '%s' ''
	fi
}


#---------------------------------------------------------------------
## Log, internal to this file.
## @Type Private
## @param Level to log at (ERROR or such, aligned to space)
## @param Color of level
## @param The log message to log
## @param Force log to stdout (0 or 1)
## @param Optional extra file to log to.
#---------------------------------------------------------------------
log() {
	# Log file exists?
	[[ $log_file ]] || return 0
	# Log date.
	local logdate="$(log_get_date)"
	# ncm = No Color Message
	local ncm="$log_prefix $logdate ${1}${3}"
	echo "$ncm" >> "$log_file"
	# Extra log file?
	[[ $5 ]] && echo "$ncm" >> "$log_dir/$5"
	# STDOUT?
	if [[ $config_log_stdout -eq 1 || $4 -eq 1 ]]; then
		# Colors and then get rid of bell chars.
		echo "${log_color_std}${log_prefix}${log_color_none} $logdate ${2}${1}${log_color_none}${3//$'\007'}"
	fi
}

#---------------------------------------------------------------------
## Used internally in core to log raw line
## @Type Private
## @param Line to log
#---------------------------------------------------------------------
log_raw_in() {
	[[ $config_log_raw = 1 ]] && log_raw "<" "$log_color_in" "$1"
}
#---------------------------------------------------------------------
## Used internally in core to log raw line
## @Type Private
## @param Line to log
#---------------------------------------------------------------------
log_raw_out() {
	[[ $config_log_raw = 1 ]] && log_raw ">" "$log_color_out" "$1"
}


#---------------------------------------------------------------------
## Internal function to this file.
## @Type Private
## @param Prefix to use
## @param Color of prefix
## @param Message to log
#---------------------------------------------------------------------
log_raw() {
	# Log file exists?
	[[ $log_file ]] || return 0
	# No Color Message
	# Log date.
	local logdate="$(log_get_date)"
	# No colors for file
	echo "$1 $logdate $3" >> "$log_dir/raw.log"
	# STDOUT?
	if [[ $config_log_stdout -eq 1 ]]; then
		# Get rid of bell chars.
		echo "${2}${1}${log_color_none} $logdate RAW      ${3//$'\007'}"
	fi
}

#---------------------------------------------------------------------
## Create log file.
## @Type Private
#---------------------------------------------------------------------
log_init() {
	local now
	time_get_current 'now'
	# This creates log dir for this run:
	log_dir="${config_log_dir}/${now}"
	# Security, the log may contain passwords.
	mkdir -m 700 "$log_dir"
	if [[ $? -ne 0 ]]; then
		echo "Error: couldn't create log dir"
		envbot_quit 1
	fi
	log_file="${log_dir}/main.log"
	touch "$log_file"
	if [[ $? -ne 0 ]]; then
		echo "Error: couldn't create logfile"
		envbot_quit 1
	fi

	# Should there be colors?
	if [[ $config_log_colors -eq 1 ]]; then
		local bold
		# Generate colors
		log_check_cap sgr0      log_color_none      # No color
		log_check_cap bold      bold                # Bold local
		log_check_cap 'setaf 1' log_color_error     # Red
		log_color_fatal="${log_color_error}${bold}" # Red bold
		log_check_cap 'setaf 3' log_color_warning   # Yellow
		log_check_cap 'setaf 2' log_color_info      # Green
		log_check_cap 'setaf 4' log_color_std       # Blue bold, for standard prefix
		log_color_std+="${bold}"
		log_check_cap 'setaf 5' log_color_in        # Magenta, for prefix
		log_check_cap 'setaf 6' log_color_out       # Cyan, for prefix
	fi

	echo "Log directory is $log_dir"
}
