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

# Internal function to this file
do_log() {
	echo "$1" >> "$log_file"
	if [[ $config_log_stdout -eq 1 ]]; then
		echo "$1"
	fi
}

log_prefix="---------------"
log_raw_in() {
	do_log "< $(date +'%Y-%m-%d %k:%M:%S') $@"
}
log_raw_out() {
	do_log "> $(date +'%Y-%m-%d %k:%M:%S') $@"
}
log() {
	do_log "$log_prefix $(date +'%Y-%m-%d %k:%M:%S') $@"
}

# Allways print to STDOUT as well
log_stdout() {
	local logstring="$log_prefix $(date +'%Y-%m-%d %k:%M:%S') $@"
	echo "$logstring" >> "$log_file"
	echo "$logstring"
}

log_init() {
	# This creates logfile for this run:
	log_file="${config_log_dir}/$(date -u +%s).log"
	touch "$log_file"
	if [[ $? -ne 0 ]]; then
		echo "Error: couldn't create logfile"
		exit 1
	fi

	echo "Logfile is $log_file"
}
