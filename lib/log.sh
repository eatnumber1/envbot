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
#---------------------------------------------------------------------
## Logging API
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## Log a fatal error to the main log file as well as STDOUT.
## @Type API
## @param The log message to log
#---------------------------------------------------------------------
log_fatal() {
	log_stdout "FATAL:   $1"
}

#---------------------------------------------------------------------
## Log a fatal error to a specific log file as well as
## the main log file and STDOUT.
## @Type API
## @param The extra log file (relative to the current log dir)
## @param The log message to log
#---------------------------------------------------------------------
log_fatal_file() {
	log_stdout_file "$1" "FATAL:   $2"
}


#---------------------------------------------------------------------
## Log an error to the main log file as well as STDOUT.
## @Type API
## @param The log message to log
#---------------------------------------------------------------------
log_error() {
	log_stdout "ERROR:   $1"
}

#---------------------------------------------------------------------
## Log an error to a specific log file as well as
## the main log file and STDOUT.
## @Type API
## @param The extra log file (relative to the current log dir)
## @param The log message to log
#---------------------------------------------------------------------
log_error_file() {
	log_stdout_file "$1" "ERROR:   $2"
}


#---------------------------------------------------------------------
## Log a warning to the main log file as well as STDOUT.
## @Type API
## @param The log message to log
#---------------------------------------------------------------------
log_warning() {
	log_stdout "WARNING: $1"
}

#---------------------------------------------------------------------
## Log a warning to a specific log file as well as
## the main log file and STDOUT.
## @Type API
## @param The extra log file (relative to the current log dir)
## @param The log message to log
#---------------------------------------------------------------------
log_warning_file() {
	log_stdout_file "$1" "WARNING: $2"
}


#---------------------------------------------------------------------
## Log an info message to the main log file.
## @Type API
## @param The log message to log
#---------------------------------------------------------------------
log_info() {
	log "INFO:    $1"
}

#---------------------------------------------------------------------
## Log an info message to the main log file and STDOUT.
## Normally this shouldn't be used by modules.
## It is used for things like "Connecting"
## @Type API
## @param The log message to log
#---------------------------------------------------------------------
log_info_stdout() {
	log_stdout "INFO:    $1"
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
	log_stdout_file "$1" "INFO:    $2"
}

#---------------------------------------------------------------------
## Log an info message to a specific log file as well as STDOUT.
## @Type API
## @param The extra log file (relative to the current log dir)
## @param The log message to log
#---------------------------------------------------------------------
log_info_file() {
	log_file "$1" "INFO:    $2"
}

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

#---------------------------------------------------------------------
## Logging prefix
## @Type Private
#---------------------------------------------------------------------
log_prefix="---------------"

#---------------------------------------------------------------------
## Get human readable date.
## @Type Private
## @Stdout Human readable date
#---------------------------------------------------------------------
log_get_date() {
	date +'%Y-%m-%d %k:%M:%S'
}

#---------------------------------------------------------------------
## Log to main log file.
## @Type Private
## @param The log message to log
#---------------------------------------------------------------------
log() {
	log_write "$log_prefix $(log_get_date) $@"
}

#---------------------------------------------------------------------
## Log to to a specific log file as well as main log.
## @Type Private
## @param The extra log file (relative to the current log dir)
## @param The log message to log
#---------------------------------------------------------------------
log_file() {
	log_write "$log_prefix $(log_get_date) $2" "0" "$1"
}

#---------------------------------------------------------------------
## Always print log message to STDOUT as well
## @Type Private
## @param The log message to log
#---------------------------------------------------------------------
log_stdout() {
	log_write "$log_prefix $(log_get_date) $@" "1"
}

#---------------------------------------------------------------------
## Log to to a specific log file as well as main log and STDOUT.
## @Type Private
## @param The extra log file (relative to the current log dir)
## @param The log message to log
#---------------------------------------------------------------------
log_stdout_file() {
	log_write "$log_prefix $(log_get_date) $2" "1" "$1"
}

#---------------------------------------------------------------------
## Used internally in core to log raw line
## @Type Private
## @param Line to log
#---------------------------------------------------------------------
log_raw_in() {
	[[ $config_log_raw = 1 ]] && log_write "< $(log_get_date) $@"
}
#---------------------------------------------------------------------
## Used internally in core to log raw line
## @Type Private
## @param Line to log
#---------------------------------------------------------------------
log_raw_out() {
	[[ $config_log_raw = 1 ]] && log_write "> $(log_get_date) $@"
}


#---------------------------------------------------------------------
## Internal function to this file.
## @Type Private
## @param Message to log
## @param If 1 always log to STDOUT as well
## @param may be optional extra log file
#---------------------------------------------------------------------
log_write() {
	echo "$1" >> "$log_file"
	[[ $3 ]] && echo "$1" >> "$log_dir/$3"
	if [[ $config_log_stdout -eq 1 || $2 -eq 1 ]]; then
		# Get rid of bell chars.
		echo "${1//$'\007'}"
	fi
}

#---------------------------------------------------------------------
## For debugging in core code.
## @Type Private
## @param Should be "$@" at first line of function.
#---------------------------------------------------------------------
log_debug_caller() {
	log_file debug.log "DEBUG: ${FUNCNAME[1]} called from ${BASH_SOURCE[2]}:${BASH_LINENO[1]} ${FUNCNAME[2]} with arguments: $*"
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

	echo "Log directory is $log_dir"
}
