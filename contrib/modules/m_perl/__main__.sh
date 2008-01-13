#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007-2008  EmErgE <halt.system@gmail.com>                #
#  Copyright (C) 2007-2008  Vsevolod Kozlov                               #
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
## Evaluate with perl
## @Dependencies This module depends on perl
## @Dependencies (http://www.perl.org/about.html)
## @Note This may not be safe!
#---------------------------------------------------------------------

module_perl_INIT() {
	modinit_API='2'
	modinit_HOOKS=''
	if ! hash perl > /dev/null 2>&1; then
		log_error "Couldn't find \"perl\" binary. The perl module depends on it."
		return 1
	fi
	module_perl_working_dir="$MODULE_BASE_PATH"
	commands_register "$1" 'perl' || return 1
}

module_perl_UNLOAD() {
	unset module_perl_working_dir
	unset module_perl_handler_perl
	return 0
}

module_perl_REHASH() {
	return 0
}

module_perl_handler_perl() {
	local sender="$1"
	local channel="$2"
	local sendernick=
	parse_hostmask_nick "$sender" 'sendernick'
	if access_check_capab "perl_eval" "$sender" "$channel"; then
		# If it isn't in a channel send message back to person who send it,
		# otherwise send in channel
		if ! [[ $2 =~ ^# ]]; then
			channel="$sendernick"
		fi
		local parameters="$3"
		# Extremely Safe Perl Evaluation
		local myresult="$(perl "${module_perl_working_dir}/safe_eval.pl" "$parameters")"
		send_msg "$channel" "${sendernick}: $myresult"
	else
		access_fail "$sender" "make the bot evalute perl expressions" "perl_eval"
	fi
}
