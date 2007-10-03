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

log_prefix="---------------"

# Log a fatal error to the main log file as well as STDOUT.
# Parameters
#   $1 The log message to log
log_fatal() {
	log_stdout "FATAL:   $1"
}

# Log a fatal error to a specific log file as well as
# the main log file and STDOUT.
# Parameters
#   $1 The extra log file (relative to the current log dir)
#   $2 The log message to log
log_fatal_file() {
	log_stdout_file "$1" "FATAL:   $2"
}


# Log an error to the main log file as well as STDOUT.
# Parameters
#   $1 The log message to log
log_error() {
	log_stdout "ERROR:   $1"
}

# Log an error to a specific log file as well as
# the main log file and STDOUT.
# Parameters
#   $1 The extra log file (relative to the current log dir)
#   $2 The log message to log
log_error_file() {
	log_stdout_file "$1" "ERROR:   $2"
}


# Log a warning to the main log file as well as STDOUT.
# Parameters
#   $1 The log message to log
log_warning() {
	log_stdout "WARNING: $1"
}

# Log a warning to a specific log file as well as
# the main log file and STDOUT.
# Parameters
#   $1 The extra log file (relative to the current log dir)
#   $2 The log message to log
log_warning_file() {
	log_stdout_file "$1" "WARNING: $2"
}


# Log an info message to the main log file.
# Parameters
#   $1 The log message to log
log_info() {
	log "INFO:    $1"
}

# Log an info message to the main log file and STDOUT.
# Normally this shouldn't be used by modules.
# It is used for things like "Connecting"
# Parameters
#   $1 The log message to log
log_info_stdout() {
	log_stdout "INFO:    $1"
}

# Log an info message to a specific log file as well as
# the main log file and STDOUT.
# Normally this shouldn't be used by modules.
# It is used for things like "Connecting"
# Parameters
#   $1 The extra log file (relative to the current log dir)
#   $1 The log message to log
log_info_stdout_file() {
	log_stdout_file "$1" "INFO:    $2"
}

# Log an info message to a specific log file as well as STDOUT.
# Parameters
#   $1 The extra log file (relative to the current log dir)
#   $2 The log message to log
log_info_file() {
	log_file "$1" "INFO:    $2"
}

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

# Log to main log file.
# Parameters
#   $* The log message to log
log() {
	log_write "$log_prefix $(date +'%Y-%m-%d %k:%M:%S') $@"
}

# Log to to a specific log file as well as main log.
# Parameters
#   $1 The extra log file (relative to the current log dir)
#   $2 The log message to log
log_file() {
	log_write "$log_prefix $(date +'%Y-%m-%d %k:%M:%S') $2" "0" "$1"
}

# Always print log message to STDOUT as well
# Parameters
#   $* The log message to log
log_stdout() {
	log_write "$log_prefix $(date +'%Y-%m-%d %k:%M:%S') $@" "1"
}

# Log to to a specific log file as well as main log and STDOUT.
# Parameters
#   $1 The extra log file (relative to the current log dir)
#   $2 The log message to log
log_stdout_file() {
	log_write "$log_prefix $(date +'%Y-%m-%d %k:%M:%S') $2" "1" "$1"
}

# Used internally in core
log_raw_in() {
	log_write "< $(date +'%Y-%m-%d %k:%M:%S') $@"
}
# Used internally in core
log_raw_out() {
	log_write "> $(date +'%Y-%m-%d %k:%M:%S') $@"
}


# Internal function to this file.
#  $1 = message to log
#  $2 = if 1 always log to STDOUT as well
#  $3 = may be optional extra log file
log_write() {
	echo "$1" >> "$log_file"
	[[ $3 ]] && echo "$1" >> "$log_dir/$3"
	if [[ $config_log_stdout -eq 1 ]] || [[ $2 -eq 1 ]]; then
		# Get rid of bell chars.
		echo "${1//$'\007'}"
	fi
}

# Create log file.
log_init() {
	# This creates log dir for this run:
	log_dir="${config_log_dir}/$(date -u +%s)"
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
