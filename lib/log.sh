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
	local logstring="< $(date +'%Y-%m-%d %k:%M:%S') $@"
	echo "$logstring" >> "$logfile"
}
log_raw_out() {
	local logstring="> $(date +'%Y-%m-%d %k:%M:%S') $@"
	echo "$logstring" >> "$logfile"
}
log() {
	local logstring="$log $(date +'%Y-%m-%d %k:%M:%S') $@"
	echo "$logstring" >> "$logfile"
}


# This creates logfile for this run:
logfile="${logdir}/$(date -u +%s).log"
touch "$logfile"

echo "Logfile is $logfile"