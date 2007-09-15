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
echo "Loading... Please wait"

echo "Loading config"
source bot_settings.sh

echo "Loading library functions"
# Load library functions.
source lib/log.sh
source lib/send.sh
source lib/channels.sh
source lib/parse.sh
source lib/access.sh
source lib/misc.sh

CurrentNick=""
ServerName=""
Server004=""
Server005=""
# NAMES output with UHNAMES and NAMESX
#  :photon.kuonet-ng.org 353 bashbot = #bots :@%+AnMaster!AnMaster@staff.kuonet-ng.org @ChanServ!ChanServ@services.kuonet-ng.org bashbot!rfc3092@1F1794B2:769091B3
# NAMES output with NAMESX only:
#  :hurricane.KuoNET.org 353 bashbot = #test :bashbot ~@Brain ~@EmErgE &@AnMaster/kng

Server_UHNAMES=0
Server_NAMESX=0

quit_bot() {
	for module in $modules_FINALISE; do
		${module}_FINALISE
	done
	log "Bot quit gracefully"
	exec 3<&-
	if [[ $2 ]]; then
		exit $2
	else
		exit 0
	fi
}


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
		send_raw "PONG :$pingdata"
	fi
}

validate_config

IRC_CONNECT(){ #$1=nick $2=passwd
	local ghost=0
	local on_nick=1
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
		elif  [[ $( echo $line | cut -d' ' -f2 ) == '002'  ]]; then
			if [[ $line =~ Your\ host\ is\ ([^ ,]*)  ]]; then # just to get the regex, this should always be true
				ServerName="${BASH_REMATCH[1]}"
			fi
		elif  [[ $( echo $line | cut -d' ' -f2 ) == '004' ]]; then
			Server004="$( echo $line | cut -d' ' -f4- )"
		elif  [[ $( echo $line | cut -d' ' -f2 ) == '005' ]]; then
			Server005="$Server005 $( echo $line | cut -d' ' -f4- )"
			# Enable NAMESX is supported.
			if [[ $line =~ NAMESX ]]; then
				send_raw "PROTOCTL NAMESX"
				Server_NAMESX=1
			fi
			if [[ $line =~ UHNAMES ]]; then
				send_raw "PROTOCTL UHNAMES"
				Server_UHNAMES=1
			fi
		fi
		if [[ $line =~ "Looking up your hostname" ]]; then #en galant entré :P
			log "logging in as $firstnick..."
			send_nick "$firstnick"
			# FIXME: THIS IS HACKISH AND MAY BREAK
			CurrentNick="$firstnick"
			send_raw "USER $ident 0 * :${gecos}"
		fi
		handle_ping "$line"
		if [[ $( echo $line | cut -d' ' -f2 ) == '433'  ]]; then
			ghost=1
			if [[ $on_nick -eq 3 ]]; then
				log "Third nick is ALSO in use. I give up"
				quit_bot 2
			fi
			if [[ $on_nick -eq 2 ]]; then
				log "Second nick is ALSO in use, trying third"
				send_nick "$thirdnick"
				on_nick=3
			fi
			log "First nick is in use, trying second"
			send_nick "$secondnick"
			on_nick=2
			# FIXME: THIS IS HACKISH AND MAY BREAK
			CurrentNick="$secondnick"
			sleep 1
		fi
		if [[ $( echo $line | cut -d' ' -f2 ) == '376'  ]]; then # 376 = End of motd
			if [[ $ghost == 1 ]]; then
				log "recovering ghost"
				send_msg "Nickserv" "GHOST $firstnick $passwd"
				sleep 2
				send_nick "$firstnick"
			fi
			log "identifying..."
			[ -n "$passwd" ] && send_msg "Nickserv" "IDENTIFY $passwd"
			sleep 1
			channels_join_config_channels
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
			"FINALISE")
				modules_FINALISE="$modules_before_connect $module"
				;;
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
			"on_numeric")
				modules_on_numeric="$modules_on_numeric $module"
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

echo "Loading modules"
# Load modules
for module in $modules; do
	if [ -f "modules/${module}.sh" ]; then
		. modules/${module}.sh
		if [[ $? -eq 0 ]]; then
			loaded_modules="$loaded_modules $module"
			add_hooks "$module"
		fi
	else
		log "WARNING: $module doesn't exist! Removing it from list"
	fi
done


while true; do
	for module in $modules_before_connect; do
		${module}_before_connect
	done
	IRC_CONNECT
	trap 'send_quit "ctrl-C" ; quit_bot 1' TERM INT
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
		if [[ $line =~ :${ServerName}\ ([0-9]{3})\ ([^ ]+)\ (.*) ]]; then
			# this is a numeric
			numeric="${BASH_REMATCH[1]}"
			mynick="${BASH_REMATCH[2]}"
			# Slight sanity check
			if [[ $mynick != $CurrentNick ]]; then
				log 'WARNING: Own nick desynced!'
				log "WARNING: It should be $CurrentNick but is $mynick"
				log "WARNING: Correcting own nick and lets hope that doesn't break anything"
				CurrentNick="$mynick"
			fi
			numericdata="${BASH_REMATCH[2]}"
			for module in $modules_on_numeric; do
				${module}_on_numeric "$numeric" "$numericdata"
				if [[ $? -ne 0 ]]; then
					break
				fi
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+PRIVMSG\ ([^:]*)(.*) ]]; then
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
	sleep 1
done
