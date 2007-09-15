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
source bot_settings.sh

source lib/log.sh
source lib/send.sh
source lib/parse.sh
source lib/access.sh

handle_ping() {
	if [[ "$1" =~ ^PING.* ]] ;then
		local pingdata="$(parse_get_colon_arg "$1")"
		log "$pingdata pinged me, answering ..."
		log_raw_out "PONG :$pingdata"
		send_raw "PONG :$pingdata"
	fi
}

IRC_CONNECT(){ #$1=nick $2=passwd $3=flag if nick should be recovered :P
	ghost=0
	echo "Connecting..."
	exec 3<&-
	exec 3<> "/dev/tcp/${server}"
	while read -d $'\n' -u 3 line; do
		log_raw_in "$line"
		if [[ $line =~ "response" ]] || [[ $line =~ "Found your hostname" ]]; then #en galant entr� :P
			log "logging in as $1..."
			send_raw "NICK $1"
			send_raw "USER rfc3092 0 * :${identstring}"
		fi
		handle_ping "$line"
		if [[ $( echo $line | cut -d' ' -f2 ) == '433'  ]]; then
			ghost=1
			IRC_CONNECT $1-crap NULL 1 #i'm lazy, this works :/
			sleep 2
			break
		fi
		if [[ $( echo $line | cut -d' ' -f2 ) == '376'  ]]; then # 376 = End of motd
			if [[ $3 == 1 ]]; then
				log "recovering ghost"
				send_msg "Nickserv" "GHOST $nick $passwd"
				sleep 2
				send_raw "NICK $nick"
			fi
			log "identifying..."
			send_msg "Nickserv" "IDENTIFY $passwd"
			sleep 1
			send_raw "JOIN $channel"
			break
		fi
	done;
}

# Load modules
loaded_modules=""
for module in $modules; do
	if [ -f "modules/${module}.sh" ]; then
		. modules/${module}.sh
		loaded_modules="$loaded_modules $module"
	else
		log "WARNING: $module doesn't exist! Removing it from list"
	fi
done


while true; do
	sleep 1
	IRC_CONNECT $nick $passwd 0
	trap 'echo -e "QUIT : ctrl-C" ; exit 123 >&3 ; sleep 2 ; exit 1' TERM INT
	unset count
	unset i
	unset last_query
	last_query='null'
	for module in $loaded_modules; do
		${module}_init
	done


	while read -u 3 -t 600 line ; do #-d $'\n'
		line=${line//$'\r'/}
		log_raw_in "$line"
		# :Brain!brain@staff.kuonet.org PRIVMSG #test :aj
		if [[ "$line" =~ :([^:]*)\ PRIVMSG\ ([^:]*)(.*) ]]; then #eval =~ '=~' ?
			sender="${BASH_REMATCH[1]}"
			target="${BASH_REMATCH[2]}"
			query="${BASH_REMATCH[3]}"
			query="${query#*:}"
			for module in $loaded_modules; do
				${module}_on_PRIVMSG "$sender" "$target" "$query"
			done
		elif [[ $line =~ ^[^:] ]] ;then
			log "handling this ..."
			handle_ping "$line"
		fi
	done

	log "DIED FOR SOME REASON"
done
