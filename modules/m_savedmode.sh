#!/bin/bash

module_savedmode_INIT() {
	modinit_API='2'
	modinit_HOOKS='after_load on_JOIN'
}

module_savedmode_REHASH() {
	return 0
}

module_savedmode_UNLOAD() {
	return 0
}

module_savedmode_after_load() {
	modules_depends_register "savedmode" "sqlite3" || {
		# This error reporting is hackish, will fix later.
		if ! list_contains "modules_loaded" "sqlite3"; then
			log_error "The savedmode module depends upon the SQLite3 module being loaded."
		fi
		return 1
	}
	if [[ -z $config_module_savedmode_table ]]; then
		log_error "Savedmode table (config_module_savedmode_table) must be set in config to use the savedmode module."
		return 1
	fi
	if ! module_sqlite3_table_exists "$config_module_savedmode_table"; then
		log_error "savedmode module: $config_module_savedmode_table does not exist in the database file."
		log_error "savedmode module: See comment in doc/savedmode.sql for how to create the table."
	fi
}

module_savedmode_on_JOIN() {
	local my_nick my_ident my_host
	parse_hostmask "$1" 'my_nick' 'my_ident' 'my_host'
	local my_channel="$2"
	local match="$(module_sqlite3_exec_sql "SELECT nick,ident,host,operator,voice FROM $config_module_savedmode_table WHERE channel='$(module_sqlite3_clean_string "$my_channel")';")"
	if [[ $match ]]; then
		local line
		while read -r line; do
			if [[ $line =~ ([^ |]+)\|([^ |]+)\|([^ |]+)\|([0-9]+)\|([0-9]+) ]]; then
				local nick="${BASH_REMATCH[1]}"
				local ident="${BASH_REMATCH[2]}"
				local host="${BASH_REMATCH[3]}"
				local -i operator="${BASH_REMATCH[4]}"
				local -i voice="${BASH_REMATCH[5]}"
				if [[ $my_nick =~ $nick && $my_ident =~ $ident && $my_host =~ $host ]]; then
					if (( $operator )); then
						log_info "Giving $my_nick operator privs"
						send_modes "$channel" "+o $my_nick"
					elif (( $voice )); then
						log_info "Giving $my_nick voice"
						send_modes "$channel" "+v $my_nick"
					fi
				fi
			fi
		done <<< "$match"
	fi
}
