#!/bin/bash
###########################################################################
#                                                                         #
#  envbot - an irc bot in bash                                            #
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


###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

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
		echo "$1" | tr -d $'\\007'
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
		exit 1
	fi
	log_file="${log_dir}/main.log"
	touch "$log_file"
	if [[ $? -ne 0 ]]; then
		echo "Error: couldn't create logfile"
		exit 1
	fi

	echo "Log directory is $log_dir"
}
