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

log="---------------"
log_raw_in() {
	echo "< $(date +'%Y-%m-%d %k:%M:%S') $@" >> "$logfile"
}
log_raw_out() {
	echo "> $(date +'%Y-%m-%d %k:%M:%S') $@" >> "$logfile"
}
log() {
	echo "$log $(date +'%Y-%m-%d %k:%M:%S') $@" >> "$logfile"
}

# Print to STDOUT as well
log_stdout() {
	local logstring="$log $(date +'%Y-%m-%d %k:%M:%S') $@"
	echo "$logstring" >> "$logfile"
	echo "$logstring"
}

log_init() {
	# This creates logfile for this run:
	logfile="${logdir}/$(date -u +%s).log"
	touch "$logfile"
	if [[ $? -ne 0 ]]; then
		echo "Error: couldn't create logfile"
		exit 1
	fi
	
	echo "Logfile is $logfile"
}
