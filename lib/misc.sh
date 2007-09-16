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
validate_config() {
	if [ -z "$config_version" ]; then
		echo "ERROR: YOU MUST SET THE CORRECT config_version IN THE CONFIG"
		exit 1
	fi
	if [ $config_version -ne $config_current_version ]; then
		echo "ERROR: YOUR config_version IS $config_version BUT THE BOT'S CONFIG VERSION IS $config_current_version."
		echo "PLEASE UPDATE YOUR CONFIG."
		exit 1
	fi
	if [ -z "$config_firstnick" ]; then
		echo "ERROR: YOU MUST SET A config_firstnick IN THE CONFIG"
		exit 1
	fi
	if [ -z "$config_log_dir" ]; then
		echo "ERROR: YOU MUST SET A config_log_dir IN THE CONFIG"
		exit 1
	fi
	if [ -z "$config_log_stdout" ]; then
		echo "ERROR: YOU MUST SET config_log_stdout IN THE CONFIG"
		exit 1
	fi
	if [ -z "${config_owners[1]}" ]; then
		echo "ERROR: YOU MUST SET AT LEAST ONE OWNER IN EXAMPLE CONFIG"
		echo "       AND THAT OWNER MUST BE THE FIRST ONE (config_owners[1] that is)."
		exit 1
	fi
	if [ -z "${config_autojoin_channels[1]}" ]; then
		echo "WARNING: You probably want at least one autojoin channel"
		echo "         Set config_autojoin_channels[1] at least."
	fi
}

# Remove a value from a space separated list
# $1 = list to remove from
# $2 = value to remove
# Returns new list on STDOUT
list_remove() {
	local oldlist="${!1}"
	local newlist=${oldlist//$2}
	echo "$(sed 's/^ \+//;s/ \+$//;s/ \{2,\}/ /g' <<< "$newlist")" # Get rid of the unneeded spaces.
}

