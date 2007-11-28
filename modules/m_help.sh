module_help_INIT() {
	modinit_API='2'
#	commands_register "$1" 'data' || return 1
	commands_register "$1" 'help' || return 1
}

module_help_UNLOAD() {
	unset read_module_data fetch_module_data
}

module_help_REHASH() {
	return 0
}

fetch_module_data() {
	local module_name="$1"
	local function_name="$2"
	local target_syntax="$3"
	local target_description="$4"
	
	local varname_syntax="helpentry_${module_name}_${function_name}_syntax"
	local varname_description="helpentry_${module_name}_${function_name}_description"
	if [[ -z ${!varname_syntax} || -z ${!varname_description} ]]; then
		return 1
	fi
	printf -v "$target_syntax" '%s' "${!varname_syntax}" 
	printf -v "$target_description" '%s' "${!varname_description}"
}

module_help_handler_help() {
	local sender="$1"
	local parameters="$3"
	# Icky part here...
	if [[ $parameters =~ ^([a-zA-Z0-9][^ ]*)( [^ ]+)? ]]; then
		local command_name="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
		local target
		if [[ $2 =~ ^# ]]; then
			target="$2"
		else
			parse_hostmask_nick "$sender" 'target'
		fi
		local module_name=
		commands_provides "$command_name" 'module_name'
		local function_name=
		hash_get 'commands_list' "$command_name" 'function_name'
		if [[ $function_name =~ ^module_${module_name}_handler_(.+)$ ]]; then
			function_name="${BASH_REMATCH[1]}"
		fi
		local syntax=
		local description=
		fetch_module_data "$module_name" "$function_name" syntax description || {
			send_msg "$target" "Sorry, no help for $command_name"
			return
		}
#		send_msg "$target" "$data"
		send_msg "$target" "${format_bold}${command_name}${format_bold} $syntax"
		send_msg "$target" "$description"
	else
		local sendernick=
		parse_hostmask_nick "$sender" 'sendernick'
		feedback_bad_syntax "$sendernick" "data" "<commandname>"
	fi
}
