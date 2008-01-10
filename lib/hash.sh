#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2008  Arvid Norlander                               #
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
	# Res will contain full output string, hex current char.
	local hex i res=
	for ((i=0;i<${#1};i++)); do
		# The ' is not documented in bash but it works.
		# See http://www.opengroup.org/onlinepubs/009695399/utilities/printf.html
		# for documentation of the ' syntax for printf.
		printf -v hex '%x' "'${1:i:1}"
		# Add to string
		res+=$hex
	done
	# Print to variable.
	printf -v "$2" '%s' "$res"
}

#---------------------------------------------------------------------
## Convert a string from hex to normal
## @Type Private
## @param String to convert
## @param Name of variable to return result in.
#---------------------------------------------------------------------
hash_unhexify() {
	# Res will contain full output string, unhex current char.
	local unhex i=0 res=
	for ((i=0;i<${#1};i+=2)); do
		# Convert back from hex. 2 chars at a time
		# FIXME: This will break if output would be multibyte chars.
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
	local IFS="_"
	read -r tablename indexname <<< "${1/hsh_//}"
	unset IFS
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
	# Get variable name
	hash_name_create "$1" "$2" 'varname'
	# Set it using the printf to variable
	printf -v "$varname" '%s' "$3"
}

#---------------------------------------------------------------------
## Append a value to the end of an entry in a hash array
## @Type API
## @param Table name
## @param Index
## @param Value to append
## @param Separator (optional, defaults to space)
#---------------------------------------------------------------------
hash_append() {
	local varname
	# Get variable name
	hash_name_create "$1" "$2" 'varname'
	# Append to end, or if empty just set.
	if [[ "${!varname}" ]]; then
		local sep=${4:-" "}
		printf -v "$varname" '%s' "${!varname}${sep}${3}"
	else
		printf -v "$varname" '%s' "$3"
	fi
}

#---------------------------------------------------------------------
## Opposite of <@function hash_append>, removes a value from a list
## in a hash entry
## @Type API
## @param Table name
## @param Index
## @param Value to remove
## @param Separator (optional, defaults to space)
#---------------------------------------------------------------------
hash_substract() {
	local varname
	# Get variable name
	hash_name_create "$1" "$2" 'varname'
	# If not empty try to remove value
	if [[ "${!varname}" ]]; then
		local sep=${4:-" "}
		# FIXME: substrings of the entries in the list may match :/
		local list="${!varname}"
		list="${list//$3}"
		# Remove any double $sep caused by this.
		list="${list//$sep$sep/$sep}"
		printf -v "$varname" '%s' "$list"
	fi
}

#---------------------------------------------------------------------
## Replace a value in list style hash entry.
## @Type API
## @param Table name
## @param Index
## @param Value to replace
## @param Value to replace with
## @param Separator (optional, defaults to space)
#---------------------------------------------------------------------
hash_replace() {
	local varname
	# Get variable name
	hash_name_create "$1" "$2" 'varname'
	# Append to end, or if empty just set.
	local sep=${5:-" "}
	if [[ "${!varname}" =~ (^|$sep)${3}($sep|$) ]]; then
		# FIXME: substrings of the entries in the list may match :/
		local list="${!varname}"
		list="${list//$3/$4}"
		printf -v "$varname" '%s' "$list"
	fi
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
	# Get variable name
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
	# Get variable name
	hash_name_create "$1" "$2" 'varname'
	# Now print out to variable using indirect ref to get the value.
	printf -v "$3" '%s' "${!varname}"
}

#---------------------------------------------------------------------
## Check if a list style hash entry contains a specific value.
## @Type API
## @param Table name
## @param Index
## @param Value to check for
## @param Separator (optional, defaults to space)
## @return 0 Found
## @return 1 Not found (or hash doesn't exist).
#---------------------------------------------------------------------
hash_contains() {
	local varname
	# Get variable name
	hash_name_create "$1" "$2" 'varname'

	local sep=${4:-" "}
	if [[ "${sep}${!varname}${sep}" =~ ${sep}${3}${sep} ]]; then
		return 0
	else
		return 1
	fi
}

#---------------------------------------------------------------------
## Check if a any space separated entry in a hash array contains
## a specific value.
## @Type API
## @param Table name
## @param Value to check for
## @return 0 Found
## @return 1 Not found (or hash doesn't exist).
#---------------------------------------------------------------------
hash_search() {
	# Get variable names
	eval "local vars=\"\${!hsh_${1}_*}\""
	# Append to end, or if empty just set.
	if [[ $vars ]]; then
		local var
		# Extract index.
		for var in $vars; do
			[[ "${!varname}" =~ (^| )${2}( |$) ]] && return 0
		done
	fi
	return 1
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
	# Get all variables with a prefix
	eval "local vars=\"\${!hsh_${1}_*}\""
	# If any variable, unset them.
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
	# Get all variables with a prefix
	eval "local vars=\"\${!hsh_${1}_*}\""
	# If any variable loop through and get the "normal" index.
	if [[ $vars ]]; then
		local var unhexname returnlist
		# Extract index.
		for var in $vars; do
			hash_name_getindex "$var" 'unhexname'
			returnlist+=" $unhexname"
		done
		# Return them in variable.
		printf -v "$2" '%s' "${returnlist}"
		return 0
	else
		return 2
	fi
}
