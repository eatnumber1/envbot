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

# Load library functions.
source lib/log.sh
source lib/send.sh
source lib/channels.sh
source lib/parse.sh
source lib/access.sh

CurrentNick=""

handle_nick() {
	local oldnick="$(parse_hostmask_nick "$1")"
	if [[ $oldnick == $CurrentNick ]]; then
		CurrentNick="$2"
	fi
}

handle_ping() {
	if [[ "$1" =~ ^PING.* ]] ;then
		local pingdata="$(parse_get_colon_arg "$1")"
		log "$pingdata pinged me, answering ..."
		log_raw_out "PONG :$pingdata"
		send_raw "PONG :$pingdata"
	fi
}

if [ -z "${owners[1]}" ]; then
	echo "ERROR: YOU MUST SET AT LEAST ONE OWNER IN EXAMPLE CONFIG"
	echo "       AND THAT OWNER MUST BE THE FIRST ONE (owners[1] that is)."
	exit 1
fi


IRC_CONNECT(){ #$1=nick $2=passwd $3=flag if nick should be recovered :P
	ghost=0
	echo "Connecting..."
	exec 3<&-
	exec 3<> "/dev/tcp/${server}"
	while read -d $'\n' -u 3 line; do
		# Part of motd, that goes to dev null.
		if  [[ $( echo $line | cut -d' ' -f2 ) == '372'  ]]; then
			continue
		fi
		log_raw_in "$line"
		# Start of motd, note that we don't display that.
		if  [[ $( echo $line | cut -d' ' -f2 ) == '375'  ]]; then
			log "Motd is not displayed in log"
		fi
		if [[ $line =~ "Looking up your hostname" ]]; then #en galant entré :P
			log "logging in as $1..."
			send_nick "$1"
			CurrentNick="$1"
			send_raw "USER $ident 0 * :${gecos}"
		fi
		handle_ping "$line"
		if [[ $( echo $line | cut -d' ' -f2 ) == '433'  ]]; then
			ghost=1
			IRC_CONNECT $secondnick NULL 1 #i'm lazy, this works :/
			sleep 2
			break
		fi
		if [[ $( echo $line | cut -d' ' -f2 ) == '376'  ]]; then # 376 = End of motd
			if [[ $3 == 1 ]]; then
				log "recovering ghost"
				send_msg "Nickserv" "GHOST $nick $passwd"
				sleep 2
				send_nick "$nick"
				# FIXME: THIS IS HACKISH AND MAY BREAK
				CurrentNick="$nick"
			fi
			log "identifying..."
			[ -n "$passwd" ] && send_msg "Nickserv" "IDENTIFY $passwd"
			sleep 1
			channels_join "$channel"
			break
		fi
	done;
}


add_hooks() {
	local module="$1"
	local hooks="$(${module}_INIT)"
	local hook
	for hook in $hooks; do
		case $hook in
			"before_connect")
				modules_before_connect="$modules_before_connect $module"
				;;
			"after_connect")
				modules_after_connect="$modules_after_connect $module"
				;;
			"on_NOTICE")
				modules_on_NOTICE="$modules_on_NOTICE $module"
				;;
			"on_PRIVMSG")
				modules_on_PRIVMSG="$modules_on_PRIVMSG $module"
				;;
			"on_KICK")
				modules_on_KICK="$modules_on_KICK $module"
				;;
			"on_JOIN")
				modules_on_="$modules_on_JOIN $module"
				;;
			"on_PART")
				modules_on_PART="$modules_on_PART $module"
				;;
			"on_NICK")
				modules_on_NICK="$modules_on_NICK $module"
				;;
			"on_raw")
				modules_on_raw="$modules_on_raw $module"
				;;
			*)
				log "ERROR: Unknown hook $hook requested. Module may malfunction. Shutting down bot to prevent damage"
				exit 1
				;;
		esac
	done
}

# Load modules
loaded_modules=""
modules_before_connect=""
modules_after_connect=""
modules_on_NOTICE=""
modules_on_PRIVMSG=""
modules_on_raw=""

for module in $modules; do
	if [ -f "modules/${module}.sh" ]; then
		. modules/${module}.sh
		loaded_modules="$loaded_modules $module"
		add_hooks "$module"
	else
		log "WARNING: $module doesn't exist! Removing it from list"
	fi
done


while true; do
	sleep 1
	for module in $modules_before_connect; do
		${module}_before_connect
	done
	IRC_CONNECT $nick $passwd 0
	trap 'send_raw "QUIT :ctrl-C" ; exit 123 >&3 ; sleep 2 ; exit 1' TERM INT
	for module in $modules_after_connect; do
		${module}_after_connect
	done


	while read -u 3 -t 600 line ; do #-d $'\n'
		line=${line//$'\r'/}
		log_raw_in "$line"
		for module in $modules_on_raw; do
			${module}_on_raw "$line"
			if [[ $? -ne 0 ]]; then
				# TODO: Check that this does what it should.
				continue 2
			fi
		done
		# :Brain!brain@staff.kuonet.org PRIVMSG #test :aj
		if [[ "$line" =~ ^:([^ ]*)[\ ]+PRIVMSG\ ([^:]*)(.*) ]]; then
			sender="${BASH_REMATCH[1]}"
			target="${BASH_REMATCH[2]}"
			query="${BASH_REMATCH[3]}"
			query="${query#*:}"
			for module in $modules_on_PRIVMSG; do
				${module}_on_PRIVMSG "$sender" "$target" "$query"
				if [[ $? -ne 0 ]]; then
					break
				fi
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+NOTICE\ ([^:]*)(.*) ]]; then
			sender="${BASH_REMATCH[1]}"
			target="${BASH_REMATCH[2]}"
			query="${BASH_REMATCH[3]}"
			query="${query#*:}"
			for module in $modules_on_NOTICE; do
				${module}_on_PRIVMSG "$sender" "$target" "$query"
				if [[ $? -ne 0 ]]; then
					break
				fi
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+NICK\ (.*) ]]; then
			sender="${BASH_REMATCH[1]}"
			newnick="${BASH_REMATCH[2]}"
			# Check if it was our own nick
			handle_nick "$sender" "$newnick"
			for module in $modules_on_NICK; do
				${module}_on_NICK "$sender" "$newnick"
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+JOIN\ :(.*) ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			# Check if it was our own nick that joined
			channels_handle_join "$sender" "$channel"
			for module in $modules_on_JOIN; do
				${module}_on_JOIN "$sender" "$channel"
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+PART\ (#[^ ]+)(\ :(.*))? ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			reason="${BASH_REMATCH[4]}"
			# Check if it was our own nick that joined
			channels_handle_part "$sender" "$channel" "$reason"
			for module in $modules_on_JOIN; do
				${module}_on_PART "$sender" "$channel" "$reason"
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+KICK\ (#[^ ]+)\ ([^ ]+)(\ :(.*))? ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			kicked="${BASH_REMATCH[3]}"
			reason="${BASH_REMATCH[5]}"
			# Check if it was our own nick that joined
			channels_handle_kick "$sender" "$channel" "$kicked" "$reason"
			for module in $modules_on_KICK; do
				${module}_on_KICK "$sender" "$channel" "$kicked" "$reason"
			done
		elif [[ $line =~ ^[^:] ]] ;then
			log "handling this ..."
			handle_ping "$line"
		fi
	done

	log "DIED FOR SOME REASON"
done
