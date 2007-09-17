#!/usr/bin/env bash
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

config_current_version=6

echo "Loading library functions"
# Load library functions.
source lib/log.sh
source lib/send.sh
source lib/channels.sh
source lib/parse.sh
source lib/access.sh
source lib/misc.sh
source lib/modules.sh

validate_config
log_init
# Now logging functions can be used.

nick_current=""
server_name=""
server_004=""
# See http://www.irc.org/tech_docs/005.html for an incomplete list.
server_005=""
# NAMES output with UHNAMES and NAMESX
#  :photon.kuonet-ng.org 353 bashbot = #bots :@%+AnMaster!AnMaster@staff.kuonet-ng.org @ChanServ!ChanServ@services.kuonet-ng.org bashbot!rfc3092@1F1794B2:769091B3
# NAMES output with NAMESX only:
#  :hurricane.KuoNET.org 353 bashbot = #test :bashbot ~@Brain ~@EmErgE &@AnMaster/kng
server_UHNAMES=0
server_NAMESX=0
# These are passed in a slightly odd way in 005 so we do them here.
server_EXCEPTS=""
server_INVEX=""

# In case we don't get a 005, make some sane defaults.
server_CHMODES_LISTMODES="b"
server_CHMODES_ALWAYSPARAM="k"
server_CHMODES_PARAMONSET="l"
server_CHMODES_SIMPLE="imnpst"
server_PREFIX_modes="ov"
server_PREFIX_prefixes="@+"

# Get some common data out of 005, the whole will also be saved to
# $server_005 for any module to use via parse_005().
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
			server_EXCEPTS="${BASH_REMATCH[2]}"
		else
			server_EXCEPTS="e"
		fi
	fi
	if [[ $line =~ INVEX(=([^ ]+))? ]]; then
		# Some, but not all also send what char the modes for INVEX is.
		# If it isn't sent, guess one +I
		if [[ ${BASH_REMATCH[2]} ]]; then
			server_INVEX="${BASH_REMATCH[2]}"
		else
			server_INVEX="I"
		fi
	fi
	if [[ $line =~ PREFIX=(\(([^ \)]+)\)([^ ]+)) ]]; then
		server_PREFIX="${BASH_REMATCH[1]}"
		server_PREFIX_modes="${BASH_REMATCH[2]}"
		server_PREFIX_prefixes="${BASH_REMATCH[3]}"
	fi
	if [[ $line =~ CHANMODES=([^ ,]+),([^ ,]+),([^ ,]+),([^ ,]+) ]]; then
		server_CHMODES_LISTMODES="${BASH_REMATCH[1]}"
		server_CHMODES_ALWAYSPARAM="${BASH_REMATCH[2]}"
		server_CHMODES_PARAMONSET="${BASH_REMATCH[3]}"
		server_CHMODES_SIMPLE="${BASH_REMATCH[4]}"
	fi
	# Enable NAMESX is supported.
	if [[ $line =~ NAMESX ]]; then
		send_raw "PROTOCTL NAMESX"
		server_NAMESX=1
	fi
	# Enable UHNAMES if it is there.
	if [[ $line =~ UHNAMES ]]; then
		send_raw "PROTOCTL UHNAMES"
		server_UHNAMES=1
	fi
}

handle_numerics() { # $1 = numeric, $2 = target (self), $3 = data
	# Slight sanity check
	if [[ $2 != $nick_current ]]; then
		log_stdout 'WARNING: Own nick desynced!'
		log_stdout "WARNING: It should be $nick_current but is $2"
		log_stdout "WARNING: Correcting own nick and lets hope that doesn't break anything"
		nick_current="$2"
	fi
}

handle_nick() {
	local oldnick="$(parse_hostmask_nick "$1")"
	if [[ $oldnick == $nick_current ]]; then
		nick_current="$2"
	fi
}

handle_ping() {
	if [[ "$1" =~ ^PING.* ]] ;then
		local pingdata="$(parse_get_colon_arg "$1")"
		log "$pingdata pinged me, answering ..."
		send_raw "PONG :$pingdata"
	fi
}

handle_nick_in_use() {
	if [[ $on_nick -eq 3 ]]; then
		log_stdout "Third nick is ALSO in use. I give up"
		quit_bot 2
	fi
	if [[ $on_nick -eq 2 ]]; then
		log_stdout "Second nick is ALSO in use, trying third"
		send_nick "$config_thirdnick"
		nick_current="$config_thirdnick"
		on_nick=3
	fi
	log_stdout "First nick is in use, trying second"
	send_nick "$config_secondnick"
	on_nick=2
	# FIXME: THIS IS HACKISH AND MAY BREAK
	nick_current="$config_secondnick"
	sleep 1
}

IRC_CONNECT(){
	on_nick=1
	log_stdout "Connecting..."
	exec 3<&-
	exec 3<> "/dev/tcp/${config_server}"
	while read -d $'\n' -u 3 line; do
		for module in $modules_on_connect; do
			module_${module}_on_connect "$line"
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
				server_name="${BASH_REMATCH[1]}"
			fi
		elif  [[ $( echo $line | cut -d' ' -f2 ) == '004' ]]; then
			server_004="$( echo $line | cut -d' ' -f4- )"
			server_004=$(tr -d $'\r\n' <<< "$server_004")  # Get rid of ending newline
		elif  [[ $( echo $line | cut -d' ' -f2 ) == '005' ]]; then
			server_005="$server_005 $( echo $line | cut -d' ' -f4- )"
			server_005=$(tr -d $'\r\n' <<< "$server_005") # Get rid of newlines
			server_005="${server_005/ :are supported by this server/}" # Get rid of :are supported by this server
			handle_005 "$line"
		elif [[ $line =~ "Looking up your hostname" ]]; then
			log_stdout "logging in as $config_firstnick..."
			send_nick "$config_firstnick"
			# FIXME: THIS IS HACKISH AND MAY BREAK
			nick_current="$config_firstnick"
			# If a server password is set, send it.
			[[ $config_server_passwd ]] && send_raw "PASS $config_server_passwd"
			send_raw "USER $config_ident 0 * :${config_gecos}"
		fi
		handle_ping "$line"
		if [[ $( echo $line | cut -d' ' -f2 ) == '433'  ]]; then # Nick in use.
			handle_nick_in_use
		elif [[ $( echo $line | cut -d' ' -f2 ) == '432'  ]]; then # Erroneous Nickname Being Held...
			handle_nick_in_use
		elif [[ $( echo $line | cut -d' ' -f2 ) == '376'  ]]; then # 376 = End of motd
			sleep 1
			log_stdout 'Connected'
			break
		fi
	done;
}

echo "Loading modules"
# Load modules
modules_load_from_config


while true; do
	for module in $modules_before_connect; do
		module_${module}_before_connect
	done
	IRC_CONNECT
	trap 'send_quit "ctrl-C" ; quit_bot 1' TERM INT
	for module in $modules_after_connect; do
		module_${module}_after_connect
	done


	while read -u 3 -t 600 line ; do #-d $'\n'
		line=${line//$'\r'/}
		log_raw_in "$line"
		for module in $modules_on_raw; do
			module_${module}_on_raw "$line"
			if [[ $? -ne 0 ]]; then
				# TODO: Check that this does what it should.
				continue 2
			fi
		done
		if [[ $line =~ :${server_name}\ ([0-9]{3})\ ([^ ]+)\ (.*) ]]; then
			# this is a numeric
			numeric="${BASH_REMATCH[1]}"
			numericdata="${BASH_REMATCH[3]}"
			handle_numerics "$numeric" "${BASH_REMATCH[2]}" "$numericdata"
			for module in $modules_on_numeric; do
				module_${module}_on_numeric "$numeric" "$numericdata"
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
				module_${module}_on_PRIVMSG "$sender" "$target" "$query"
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
				module_${module}_on_PRIVMSG "$sender" "$target" "$query"
				if [[ $? -ne 0 ]]; then
					break
				fi
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+TOPIC\ (#[^ ]+)(\ :(.*))? ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			topic="${BASH_REMATCH[4]}"
			for module in $modules_on_TOPIC; do
				module_${module}_on_TOPIC "$sender" "$channel" "$topic"
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+MODE\ (#[^ ]+)\ (.*) ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			modes="${BASH_REMATCH[3]}"
			for module in $modules_on_channel_MODE ; do
				module_${module}_on_channel_MODE "$sender" "$channel" "$modes"
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+NICK\ (.*) ]]; then
			sender="${BASH_REMATCH[1]}"
			newnick="${BASH_REMATCH[2]}"
			# Check if it was our own nick
			handle_nick "$sender" "$newnick"
			for module in $modules_on_NICK; do
				module_${module}_on_NICK "$sender" "$newnick"
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+JOIN\ :(.*) ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			# Check if it was our own nick that joined
			channels_handle_join "$sender" "$channel"
			for module in $modules_on_JOIN; do
				module_${module}_on_JOIN "$sender" "$channel"
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+PART\ (#[^ ]+)(\ :(.*))? ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			reason="${BASH_REMATCH[4]}"
			# Check if it was our own nick that joined
			channels_handle_part "$sender" "$channel" "$reason"
			for module in $modules_on_JOIN; do
				module_${module}_on_PART "$sender" "$channel" "$reason"
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+KICK\ (#[^ ]+)\ ([^ ]+)(\ :(.*))? ]]; then
			sender="${BASH_REMATCH[1]}"
			channel="${BASH_REMATCH[2]}"
			kicked="${BASH_REMATCH[3]}"
			reason="${BASH_REMATCH[5]}"
			# Check if it was our own nick that joined
			channels_handle_kick "$sender" "$channel" "$kicked" "$reason"
			for module in $modules_on_KICK; do
				module_${module}_on_KICK "$sender" "$channel" "$kicked" "$reason"
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+QUIT(\ :(.*))? ]]; then
			sender="${BASH_REMATCH[1]}"
			reason="${BASH_REMATCH[3]}"
			for module in $modules_on_QUIT; do
				module_${module}_on_QUIT "$sender" "$reason"
			done
		elif [[ "$line" =~ ^:([^ ]*)[\ ]+KILL\ ([^ ]*)\ :([^ ]*)\ \((.*)\) ]]; then
			sender="${BASH_REMATCH[1]}"
			target="${BASH_REMATCH[2]}"
			path="${BASH_REMATCH[3]}"
			reason="${BASH_REMATCH[4]}"
			# I don't think we need to check if we were the target or not,
			# the bot doesn't need to care as far as I can see.
			for module in $modules_on_KILL; do
				module_${module}_on_KILL "$sender" "$target" "$path" "$reason"
			done
		elif [[ $line =~ ^[^:] ]] ;then
			handle_ping "$line"
			if [[ "$line" =~ ^ERROR\ :(.*) ]]; then
				error="${BASH_REMATCH[1]}"
				log_stdout "Got ERROR from server: $error"
				for module in $modules_on_server_ERROR; do
						module_${module}_on_server_ERROR "$error"
				done
			fi
		fi
	done

	log "DIED FOR SOME REASON"
	for module in $modules_after_disconnect; do
		module_${module}_after_disconnect
	done
	# Don't reconnect right away. We might get throttled and other nasty stuff.
	sleep 10
done
