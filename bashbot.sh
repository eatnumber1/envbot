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
if [[ $? -ne 0 ]]; then
	echo "Error: couldn't load config from bot_settings.sh"
	exit 1
fi

echo "Loading library functions"
# Load library functions.
source lib/log.sh
source lib/send.sh
source lib/channels.sh
source lib/parse.sh
source lib/access.sh
source lib/misc.sh

validate_config
log_init
# Now logging functions can be used.

CurrentNick=""
ServerName=""
Server004=""
# See http://www.irc.org/tech_docs/005.html for an incomplete list.
Server005=""
# NAMES output with UHNAMES and NAMESX
#  :photon.kuonet-ng.org 353 bashbot = #bots :@%+AnMaster!AnMaster@staff.kuonet-ng.org @ChanServ!ChanServ@services.kuonet-ng.org bashbot!rfc3092@1F1794B2:769091B3
# NAMES output with NAMESX only:
#  :hurricane.KuoNET.org 353 bashbot = #test :bashbot ~@Brain ~@EmErgE &@AnMaster/kng
Server_UHNAMES=0
Server_NAMESX=0
# These are passed in a slightly odd way in 005 so we do them here.
ServerEXCEPTS=""
ServerINVEX=""

# In case we don't get a 005, make some sane defaults.
ServerCHMODES_LISTMODES="b"
ServerCHMODES_ALWAYSPARAM="k"
ServerCHMODES_PARAMONSET="l"
ServerCHMODES_SIMPLE="imnpst"
ServerPREFIX_modes="ov"
ServerPREFIX_prefixes="@+"

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

# Get some common data out of 005, the whole will also be saved to
# $Server005 for any module to use via parse_005().
# This function is for cases that needs special action, like NAMESX
# and UHNAMES.
# This should be called directly after recieving a part of the 005!
# $1 = That part.
handle_005() {
	# Example from freenode:
	# :heinlein.freenode.net 005 bashbot IRCD=dancer CAPAB CHANTYPES=# EXCEPTS INVEX CHANMODES=bdeIq,k,lfJD,cgijLmnPQrRstz CHANLIMIT=#:20 PREFIX=(ov)@+ MAXLIST=bdeI:50 MODES=4 STATUSMSG=@ KNOCK NICKLEN=16 :are supported by this server
	# :heinlein.freenode.net 005 bashbot SAFELIST CASEMAPPING=ascii CHANNELLEN=30 TOPICLEN=450 KICKLEN=450 KEYLEN=23 USERLEN=10 HOSTLEN=63 SILENCE=50 :are supported by this server
	local line="$1"
	if [[ $line =~ EXCEPTS(=([^ ]+))? ]]; then
		# Some, but not all also send what char the modes for EXCEPTS is.
		# If it isn't sent, guess one +e
		if [[ ${BASH_REMATCH[2]} ]]; then
			ServerEXCEPTS="${BASH_REMATCH[2]}"
		else
			ServerEXCEPTS="e"
		fi
	fi
	if [[ $line =~ INVEX(=([^ ]+))? ]]; then
		# Some, but not all also send what char the modes for INVEX is.
		# If it isn't sent, guess one +I
		if [[ ${BASH_REMATCH[2]} ]]; then
			ServerINVEX="${BASH_REMATCH[2]}"
		else
			ServerINVEX="I"
		fi
	fi
	if [[ $line =~ PREFIX=(\(([^ \)]+)\)([^ ]+)) ]]; then
		ServerPREFIX="${BASH_REMATCH[1]}"
		ServerPREFIX_modes="${BASH_REMATCH[2]}"
		ServerPREFIX_prefixes="${BASH_REMATCH[3]}"
	fi
	if [[ $line =~ CHANMODES=([^ ,]+),([^ ,]+),([^ ,]+),([^ ,]+) ]]; then
		ServerCHMODES_LISTMODES="${BASH_REMATCH[1]}"
		ServerCHMODES_ALWAYSPARAM="${BASH_REMATCH[2]}"
		ServerCHMODES_PARAMONSET="${BASH_REMATCH[3]}"
		ServerCHMODES_SIMPLE="${BASH_REMATCH[4]}"
	fi
	# Enable NAMESX is supported.
	if [[ $line =~ NAMESX ]]; then
		send_raw "PROTOCTL NAMESX"
		Server_NAMESX=1
	fi
	# Enable UHNAMES if it is there.
	if [[ $line =~ UHNAMES ]]; then
		send_raw "PROTOCTL UHNAMES"
		Server_UHNAMES=1
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

IRC_CONNECT(){
	local ghost=0
	local on_nick=1
	log_stdout "Connecting..."
	exec 3<&-
	exec 3<> "/dev/tcp/${server}"
	while read -d $'\n' -u 3 line; do
		for module in $modules_on_connect; do
			${module}_on_connect $line
		done
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
			Server004=$(tr -d $'\r\n' <<< "$Server004")  # Get rid of ending newline
		elif  [[ $( echo $line | cut -d' ' -f2 ) == '005' ]]; then
			Server005="$Server005 $( echo $line | cut -d' ' -f4- )"
			Server005=$(tr -d $'\r\n' <<< "$Server005") # Get rid of newlines
			Server005="${Server005/ :are supported by this server/}" # Get rid of :are supported by this server
			handle_005 "$line"
		fi
		if [[ $line =~ "Looking up your hostname" ]]; then #en galant entré :P
			log_stdout "logging in as $firstnick..."
			send_nick "$firstnick"
			# FIXME: THIS IS HACKISH AND MAY BREAK
			CurrentNick="$firstnick"
			# If a server password is set, send it.
			[[ $serverpasswd ]] && send_raw "PASS $serverpasswd"
			send_raw "USER $ident 0 * :${gecos}"
		fi
		handle_ping "$line"
		if [[ $( echo $line | cut -d' ' -f2 ) == '433'  ]]; then
			ghost=1
			if [[ $on_nick -eq 3 ]]; then
				log_stdout "Third nick is ALSO in use. I give up"
				quit_bot 2
			fi
			if [[ $on_nick -eq 2 ]]; then
				log_stdout "Second nick is ALSO in use, trying third"
				send_nick "$thirdnick"
				on_nick=3
			fi
			log_stdout "First nick is in use, trying second"
			send_nick "$secondnick"
			on_nick=2
			# FIXME: THIS IS HACKISH AND MAY BREAK
			CurrentNick="$secondnick"
			sleep 1
		fi
		if [[ $( echo $line | cut -d' ' -f2 ) == '376'  ]]; then # 376 = End of motd
			if [[ $ghost == 1 ]]; then
				log_stdout "Recovering ghost"
				send_msg "Nickserv" "GHOST $firstnick $nickservpasswd"
				sleep 2
				send_nick "$firstnick"
			fi
			log_stdout "Identifying..."
			[ -n "$nickservpasswd" ] && send_msg "Nickserv" "IDENTIFY $nickservpasswd"
			sleep 1
			log_stdout 'Connected'
			log_stdout 'Joining autojoin channels'
			channels_join_config_channels
			log_stdout 'Finished joining'
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
			"on_connect")
				modules_on_connect="$modules_on_connect $module"
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
			"on_TOPIC")
				modules_on_TOPIC="$modules_on_TOPIC $module"
				;;
			"on_channel_MODE")
				modules_on_channel_MODE="$modules_on_channel_MODE $module"
				;;
			"on_JOIN")
				modules_on_="$modules_on_JOIN $module"
				;;
			"on_PART")
				modules_on_PART="$modules_on_PART $module"
				;;
			"on_KICK")
				modules_on_KICK="$modules_on_KICK $module"
				;;
			"on_QUIT")
				modules_on_QUIT="$modules_on_QUIT $module"
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
		source modules/${module}.sh
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
			numericdata="${BASH_REMATCH[3]}"
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
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+TOPIC\ (#[^ ]+)(\ :(.*))? ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			topic="${BASH_REMATCH[4]}"
			for module in $modules_on_TOPIC; do
				${module}_on_TOPIC "$sender" "$channel" "$topic"
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+MODE\ (#[^ ]+)\ (.*) ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			modes="${BASH_REMATCH[3]}"
			for module in $modules_on_channel_MODE ; do
				${module}_on_channel_MODE "$sender" "$channel" "$modes"
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
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+QUIT(\ :(.*))? ]]; then
			sender="${BASH_REMATCH[1]}"
			reason="${BASH_REMATCH[3]}"
			for module in $modules_on_QUIT; do
				${module}_on_QUIT "$sender" "$reason"
			done
		elif [[ $line =~ ^[^:] ]] ;then
			log "handling this ..."
			handle_ping "$line"
		fi
	done

	log "DIED FOR SOME REASON"
	# Don't reconnect right away. We might get throttled and other nasty stuff.
	sleep 10
done
