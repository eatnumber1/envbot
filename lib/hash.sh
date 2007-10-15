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
## Functions for working with associative arrays.
#---------------------------------------------------------------------

#---------------------------------------------------------------------
## Convert a string to hex
## @Type Private
## @param String to convert
## @param Name of variable to return result in.
#---------------------------------------------------------------------
hash_hexify() {
	local hex i res=
	for ((i=0;i<${#1};i++)); do
		printf -v hex '%x' "'${1:i:1}"
		res+=$hex
	done
	printf -v "$2" '%s' "$res"
}

#---------------------------------------------------------------------
## Convert a string from hex to normal
## @Type Private
## @param String to convert
## @param Name of variable to return result in.
#---------------------------------------------------------------------
hash_unhexify() {
	local unhex i=0 res=
	for ((i=0;i<${#1};i+=2)); do
		printf -v unhex \\"x${1:i:2}"
		res+=$unhex
	done
	printf -v "$2" '%s' "$res"
}

#---------------------------------------------------------------------
## Generate variable name for a item in the hash array.
## @Type Private
## @param Table name
## @param Index
## @param Name of variable to return result in.
#---------------------------------------------------------------------
hash_name_create() {
	local hexindex
	hash_hexify "$2" 'hexindex'
	printf -v "$3" '%s' "hsh_${1}_${hexindex}"
}

#---------------------------------------------------------------------
## Translate a variable name to an entry index name.
## @param Variable name
## @param Return value for index
#---------------------------------------------------------------------
hash_name_getindex() {
	local unhexindex tablename indexname
	local oldIFS="$IFS"
	IFS="_"
	read -r tablename indexname <<< "${1/hsh_//}"
	IFS="$oldIFS"
	hash_unhexify "$indexname" "$2"
}


#---------------------------------------------------------------------
## Sets (overwrites any older) a value in a hash array
## @Type API
## @param Table name
## @param Index
## @param Value
#---------------------------------------------------------------------
hash_set() {
	local varname
	hash_name_create "$1" "$2" 'varname'
	printf -v "$varname" '%s' "$3"
}

#---------------------------------------------------------------------
## Removes an entry (if it exists) from a hash array
## @Note If the entry does not exist, nothing will happen
## @Type API
## @param Table name
## @param Index
#---------------------------------------------------------------------
hash_unset() {
	local varname
	hash_name_create "$1" "$2" 'varname'
	unset "${varname}"
}

#---------------------------------------------------------------------
## Gets a value (if it exists) from a hash array
## @Note If value does not exist, the variable will be empty.
## @Type API
## @param Table name
## @param Index
## @param Name of variable to return result in.
#---------------------------------------------------------------------
hash_get() {
	local varname
	hash_name_create "$1" "$2" 'varname'
	printf -v "$3" '%s' "${!varname}"
}

#---------------------------------------------------------------------
## Check if an entry exists in a hash array
## @Type API
## @param Table name
## @param Index
## @return 0 If the entry exists
## @return 1 If the entry doesn't exist
#---------------------------------------------------------------------
hash_exists() {
	local varname
	hash_name_create "$1" "$2" 'varname'
	# This will return the return code we want.
	[[ "${!varname}" ]]
}

#---------------------------------------------------------------------
## Removes an entire hash array
## @Type API
## @param Table name
## @return 0 Ok
## @return 1 Other error
## @return 2 Table not found
#---------------------------------------------------------------------
hash_reset() {
	eval "local vars=\"\${!hsh_${1}_*}\""
	if [[ $vars ]]; then
		unset ${vars} || return 1
	else
		return 2
	fi
}

#---------------------------------------------------------------------
## Returns a space separated list of the indices of a hash array
## @Type API
## @param Table name
## @param Name of variable to return result in.
## @return 0 Ok
## @return 1 Other error
## @return 2 Table not found
#---------------------------------------------------------------------
hash_get_indices() {
	eval "local vars=\"\${!hsh_${1}_*}\""
	if [[ $vars ]]; then
		local var unhexname returnlist
		for var in $vars; do
			hash_name_getindex "$var" 'unhexname'
			returnlist+=" $unhexname"
		done
		printf -v "$2" '%s' "${returnlist}"
		return 0
	else
		return 2
	fi
}
