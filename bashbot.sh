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


log="---------------"
log_raw_in() {
	echo "< $(date +'%Y-%m-%d %k:%M:%S') $@"
}
log_raw_out() {
	echo "> $(date +'%Y-%m-%d %k:%M:%S') $@"
}
log() {
	echo "$log $(date +'%Y-%m-%d %k:%M:%S') $@"
}


irc_raw() {
	echo -e "$@\r" >&3
}
# $1 = who (channel or nick)
# $* = message
irc_msg() {
	local nick="$1"
	shift 1
	irc_raw "PRIVMSG ${nick} :${@}"
}
# $1 = who (channel or nick)
# $* = message
irc_notice() {
	local nick="$1"
	shift 1
	irc_raw "NOTICE ${nick} :${@}"
}

# Bad name of function, it gets the argument
# after a ":", the last multiword argument
# Only reads FIRST as data
# Returns on STDOUT
# FIXME: Can't handle a ":" in a word before the place to split
parse_get_colon_arg() {
	cut -d':' -f2- <<< "$1"
}

handle_ping() {
	if [[ "$1" =~ ^PING.* ]] ;then
		local pingdata="$(parse_get_colon_arg "$1")"
		log "$pingdata pinged me, answering ..."
		log_raw_out "PONG :$pingdata"
		irc_raw "PONG :$pingdata"
	fi
}

IRC_CONNECT(){ #$1=nick $2=passwd $3=flag if nick should be recovered :P
	ghost=0
	echo "Connecting..."
	exec 3<&-
	exec 3<> "/dev/tcp/${server}"
	while read -d $'\n' -u 3 line; do
		log_raw_in "$line"
		if [[ $line =~ "response" ]] || [[ $line =~ "Found your hostname" ]]; then #en galant entré :P
			log "logging in as $1..."
			irc_raw "NICK $1"
			irc_raw "USER rfc3092 0 * :${identstring}"
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
				irc_msg "Nickserv" "GHOST $nick $passwd"
				sleep 2
				irc_raw "NICK $nick"
			fi
			log "identifying..."
			irc_msg "Nickserv" "IDENTIFY $passwd"
			sleep 1
			irc_raw "JOIN $channel"
			break
		fi
	done;
}

# space separated list
modules="faq"
for module in $modules; do
	. modules/${module}.sh
done


while true
	do
	sleep 1
	IRC_CONNECT $nick $passwd 0
	trap 'echo -e "QUIT : ctrl-C" ; exit 123 >&3 ; sleep 2 ; exit 1' TERM INT
	unset count
	unset i
	unset last_query
	last_query='null'
	for module in $modules; do
		${module}_init
	done


	while read -u 3 -t 600 line ; do #-d $'\n'
		line=${line//$'\r'/}
		log_raw_in "$line"
		if [[ "$line" =~ [:][^:]*PRIVMSG ]]; then #eval =~ '=~' ?
			query="${line/:/}"
			query="${query#*:}"
			for module in $modules; do
				${module}_on_channel_PRIVMSG "foo" "$channel" "$query"
			done
		elif [[ $line =~ ^[^:] ]] ;then
			log "handling this ..."
			handle_ping "$line"
		fi
	done

	log "DIED FOR SOME REASON"
done
