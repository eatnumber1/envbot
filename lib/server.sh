#!/bin/bash
###########################################################################
#                                                                         #
#  envbot - an irc bot in bash                                            #
#  Copyright (C) 2007  Arvid Norlander                                    #
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

# Server info variables
server_name=""
server_004=""
# See http://www.irc.org/tech_docs/005.html for an incomplete list.
server_005=""
# NAMES output with UHNAMES and NAMESX
#  :photon.kuonet-ng.org 353 envbot = #bots :@%+AnMaster!AnMaster@staff.kuonet-ng.org @ChanServ!ChanServ@services.kuonet-ng.org bashbot!rfc3092@1F1794B2:769091B3
# NAMES output with NAMESX only:
#  :hurricane.KuoNET.org 353 envbot = #test :bashbot ~@Brain ~@EmErgE &@AnMaster/kng
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

server_nick_current=""
server_connected=0

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

# Get some common data out of 005, the whole will also be saved to
# $server_005 for any module to use via parse_005().
# This function is for cases that needs special action, like NAMESX
# and UHNAMES.
# This should be called directly after receiving a part of the 005!
# $1 = That part.
server_handle_005() {
	# Example from freenode:
	# :heinlein.freenode.net 005 envbot IRCD=dancer CAPAB CHANTYPES=# EXCEPTS INVEX CHANMODES=bdeIq,k,lfJD,cgijLmnPQrRstz CHANLIMIT=#:20 PREFIX=(ov)@+ MAXLIST=bdeI:50 MODES=4 STATUSMSG=@ KNOCK NICKLEN=16 :are supported by this server
	# :heinlein.freenode.net 005 envbot SAFELIST CASEMAPPING=ascii CHANNELLEN=30 TOPICLEN=450 KICKLEN=450 KEYLEN=23 USERLEN=10 HOSTLEN=63 SILENCE=50 :are supported by this server
	local line="$1"
	if [[ $line =~ EXCEPTS(=([^ ]+))? ]]; then
		# Some, but not all also send what char the modes for EXCEPTS is.
		# If it isn't sent, lets guess it is +e
		if [[ ${BASH_REMATCH[2]} ]]; then
			server_EXCEPTS="${BASH_REMATCH[2]}"
		else
			server_EXCEPTS="e"
		fi
	fi
	if [[ $line =~ INVEX(=([^ ]+))? ]]; then
		# Some, but not all also send what char the modes for INVEX is.
		# If it isn't sent, lets guess it is +I
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
		log "Enabled NAMESX support"
		send_raw_flood "PROTOCTL NAMESX"
		server_NAMESX=1
	fi
	# Enable UHNAMES if it is there.
	if [[ $line =~ UHNAMES ]]; then
		log "Enabled UHNAMES support"
		send_raw_flood "PROTOCTL UHNAMES"
		server_UHNAMES=1
	fi
}

server_handle_ping() {
	if [[ "$1" =~ ^PING.* ]] ;then
		local pingdata="$(parse_get_colon_arg "$1")"
		send_raw "PONG :$pingdata"
	fi
}

server_handle_numerics() { # $1 = numeric, $2 = target (self), $3 = data
	# Slight sanity check
	if [[ "$2" != "$server_nick_current" ]]; then
		log_stdout 'WARNING: Own nick desynced!'
		log_stdout "WARNING: It should be $server_nick_current but is $2"
		log_stdout "WARNING: Correcting own nick and lets hope that doesn't break anything"
		server_nick_current="$2"
	fi
}

server_handle_nick() {
	local oldnick="$(parse_hostmask_nick "$1")"
	if [[ $oldnick == $server_nick_current ]]; then
		server_nick_current="$2"
	fi
}

server_handle_nick_in_use() {
	if [[ $on_nick -eq 3 ]]; then
		log_stdout "Third nick is ALSO in use. I give up"
		bot_quit 2
	fi
	if [[ $on_nick -eq 2 ]]; then
		log_stdout "Second nick is ALSO in use, trying third"
		send_nick "$config_thirdnick"
		server_nick_current="$config_thirdnick"
		on_nick=3
	fi
	log_stdout "First nick is in use, trying second"
	send_nick "$config_secondnick"
	on_nick=2
	# FIXME: THIS IS HACKISH AND MAY BREAK
	server_nick_current="$config_secondnick"
	sleep 1
}

server_connect(){
	server_connected=0
	on_nick=1
	# HACK: Clean up if we are aborted, replaced after connect with one that sends QUIT
	trap 'transport_disconnect; rm -rvf $tmp_home; exit 1' TERM INT
	log_stdout "Connecting..."
	transport_connect "$config_server" "$config_server_port" "$config_server_ssl" "$config_server_bind" || return 1
	while transport_read_line; do
		# Check with modules first, needed so we don't skip them.
		for module in $modules_on_connect; do
			module_${module}_on_connect "$line"
		done
		# Part of motd, that goes to dev null.
		if  [[ $(cut -d' ' -f2 <<< "$line") == $numeric_RPL_MOTD ]]; then
			continue
		fi
		log_raw_in "$line"
		# Start of motd, note that we don't display that.
		if  [[ $(cut -d' ' -f2 <<< "$line") == $numeric_RPL_MOTDSTART ]]; then
			log "Motd is not displayed in log"
		elif  [[ $(cut -d' ' -f2 <<< "$line") == $numeric_RPL_YOURHOST ]]; then
			if [[ $line =~ ^:([^ ]+)  ]]; then # just to get the server name, this should always be true
				server_name="${BASH_REMATCH[1]}"
			fi
		elif  [[ $(cut -d' ' -f2 <<< "$line") == $numeric_RPL_MYINFO ]]; then
			server_004="$(cut -d' ' -f4- <<< "$line")"
			server_004=$(tr -d $'\r\n' <<< "$server_004")  # Get rid of ending newline
		elif  [[ $(cut -d' ' -f2 <<< "$line") == $numeric_RPL_ISUPPORT ]]; then
			server_005="$server_005 $(cut -d' ' -f4- <<< "$line")"
			server_005=$(tr -d $'\r\n' <<< "$server_005") # Get rid of newlines
			server_005="${server_005/ :are supported by this server/}" # Get rid of :are supported by this server
			server_handle_005 "$line"
		elif [[ $line =~ "Looking up your hostname" ]]; then
			log_stdout "logging in as $config_firstnick..."
			send_nick "$config_firstnick"
			# FIXME: THIS IS HACKISH AND MAY BREAK
			server_nick_current="$config_firstnick"
			# If a server password is set, send it.
			[[ $config_server_passwd ]] && send_raw_flood "PASS $config_server_passwd"
			send_raw_flood "USER $config_ident 0 * :${config_gecos}"
		fi
		server_handle_ping "$line"
		if [[ $(cut -d' ' -f2 <<< "$line") == $numeric_ERR_NICKNAMEINUSE ]]; then # Nick in use.
			server_handle_nick_in_use
		elif [[ $(cut -d' ' -f2 <<< "$line") == $numeric_ERR_ERRONEUSNICKNAME ]]; then # Erroneous Nickname Being Held...
			server_handle_nick_in_use
		# Just in case check for either of these
		elif [[ $(cut -d' ' -f2 <<< "$line") == $numeric_RPL_ENDOFMOTD ]]; then
			sleep 1
			log_stdout 'Connected'
			server_connected=1
			break
		fi
	done;
}
