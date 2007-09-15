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
		if [[ $line =~ ^PING.* ]] ;then
			log "${line//PING*:/} pinged me, answering ..."
			log_raw_out "PONG :${line//PING*:/}"
			irc_raw "PONG :${line//PING*:/}"
		fi
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

while true
	do
	sleep 1
	IRC_CONNECT $nick $passwd 0
	trap 'echo -e "QUIT : ctrl-C" ; exit 123 >&3 ; sleep 2 ; exit 1' TERM INT
	unset count
	unset i
	unset last_query
	last_query='null'
	i=0
	unset faq_array
	while read -d $'\n' line ;do
		i=$((i+1))
		faq_array[$i]="$line"
		done < ./faq.txt
	
	
	while read -u 3 -t 600 line ; do #-d $'\n'
		line=${line//$'\r'/}
		log_raw_in "$line"
		if [[ "$line" =~ "[:][^:]*PRIVMSG $channel" ]]; then #eval =~ '=~' ?
			query="${line/:/}"
			query="${query#*:}"
			if [[ "$query" =~ '^;faq.*' ]] ;then	#spaghetti...yummie :)
				query="${query//\;faq/}"
				query="${query/^ /}"
				query_time="$(date +%H%M)$line"
				if [[ "$last_query" != "$query_time" ]] ; then #must be atleast 1 min old or different query...
					last_query="$(date +%H%M)$line"
					if [[ "$query" -gt 0 ]] && [[ "$query" -lt 54 ]] ; then
						log "$channel :$query is numeric"
						irc_msg "$channel" "${faq_array[$query]}"
						sleep 1
					elif [[ "${#query}" -ge 3 ]] ; then
						i=0
						while [[ $i -lt "${#faq_array[*]}" ]] ; do
							i=$((i+1))
							if echo ${faq_array[$i]} | cut -d " " -f 3- | /bin/grep -i -F -m 1 "$query" ; then
								log "$channel :${faq_array[$i]}"
								irc_raw "$channel" "${faq_array[$i]}"
								sleep 1
								break 1
							fi
						done
					fi
				else
					log "ERROR : FLOOD DETECTED"
				fi
			fi
	
		elif [[ $line =~ ^[^:] ]] ;then
			log "handling this ..."
			if [[ "$line" =~ ^PING.* ]] ;then
				log "${line//PING*:/} pinged me, answering ..."
				log_raw_out "PONG :${line//PING*:/}"
				irc_raw "PONG :${line//PING*:/}"
			fi
		fi
	done

	log "DIED FOR SOME REASON"
done
