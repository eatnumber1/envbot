#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
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
#---------------------------------------------------------------------
## Server connection.
#---------------------------------------------------------------------

# Server info variables
#---------------------------------------------------------------------
## Name of server (example: server1.example.net)
## @Type API
#---------------------------------------------------------------------
server_name=""
#---------------------------------------------------------------------
## The 004 received from the server.
## @Type API
#---------------------------------------------------------------------
server_004=""
#---------------------------------------------------------------------
## The 005 received from the server. Use parse_005 to get data out of this.
## @Type API
## @Note See http://www.irc.org/tech_docs/005.html for an incomplete list of 005 values.
#---------------------------------------------------------------------
server_005=""
# NAMES output with UHNAMES and NAMESX
#  :photon.kuonet-ng.org 353 envbot = #bots :@%+AnMaster!AnMaster@staff.kuonet-ng.org @ChanServ!ChanServ@services.kuonet-ng.org bashbot!rfc3092@1F1794B2:769091B3
# NAMES output with NAMESX only:
#  :hurricane.KuoNET.org 353 envbot = #test :bashbot ~@Brain ~@EmErgE &@AnMaster/kng
#---------------------------------------------------------------------
## 1 if UHNAMES enabled, otherwise 0
## @Type API
#---------------------------------------------------------------------
server_UHNAMES=0
#---------------------------------------------------------------------
## 1 if NAMESX enabled, otherwise 0
## @Type API
#---------------------------------------------------------------------
server_NAMESX=0
# These are passed in a slightly odd way in 005 so we do them here.
#---------------------------------------------------------------------
## The mode char (if any) for ban excepts (normally +e)
## @Type API
#---------------------------------------------------------------------
server_EXCEPTS=""
#---------------------------------------------------------------------
## The mode char (if any) for invite excepts (normally +I)
## @Type API
#---------------------------------------------------------------------
server_INVEX=""

# In case we don't get a 005, make some sane defaults.
#---------------------------------------------------------------------
## List channel modes supported by server.
## @Type API
#---------------------------------------------------------------------
server_CHMODES_LISTMODES="b"
#---------------------------------------------------------------------
## "Always parameters" channel modes supported by server.
## @Type API
#---------------------------------------------------------------------
server_CHMODES_ALWAYSPARAM="k"
#---------------------------------------------------------------------
## "Parameter on set" channel modes supported by server.
## @Type API
#---------------------------------------------------------------------
server_CHMODES_PARAMONSET="l"
#---------------------------------------------------------------------
## Simple channel modes supported by server.
## @Type API
#---------------------------------------------------------------------
server_CHMODES_SIMPLE="imnpst"
#---------------------------------------------------------------------
## Prefix channel modes supported by server.
## @Type API
#---------------------------------------------------------------------
server_PREFIX_modes="ov"
#---------------------------------------------------------------------
## Channel prefixes supported by server.
## @Type API
#---------------------------------------------------------------------
server_PREFIX_prefixes="@+"

#---------------------------------------------------------------------
## What is our current nick?
## @Type API
#---------------------------------------------------------------------
server_nick_current=""
#---------------------------------------------------------------------
## 1 if we are connected, otherwise 0
## @Type API
#---------------------------------------------------------------------
server_connected=0

###########################################################################
# Internal functions to core or this file below this line!                #
# Module authors: go away                                                 #
###########################################################################

#---------------------------------------------------------------------
## Get some common data out of 005, the whole will also be saved to
## $server_005 for any module to use via parse_005().
## This function is for cases that needs special action, like NAMESX
## and UHNAMES.
## This should be called directly after receiving a part of the 005!
## @Type Private
## @param The last part of the 005.
#---------------------------------------------------------------------
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
		log_info "Enabled NAMESX support"
		send_raw_flood "PROTOCTL NAMESX"
		server_NAMESX=1
	fi
	# Enable UHNAMES if it is there.
	if [[ $line =~ UHNAMES ]]; then
		log_info "Enabled UHNAMES support"
		send_raw_flood "PROTOCTL UHNAMES"
		server_UHNAMES=1
	fi
}

#---------------------------------------------------------------------
## Respond to PING from server.
## @Type Private
## @param Raw line
## @return 0 If it was a PING
## @return 1 If it was not a PING
#---------------------------------------------------------------------
server_handle_ping() {
	if [[ "$1" =~ ^PING\ *:(.*) ]] ;then
		send_raw "PONG :${BASH_REMATCH[1]}"
		return 0
	fi
	return 1
}

#---------------------------------------------------------------------
## Handle numerics from server.
## @Type Private
## @param Numeric
## @param Target (self)
## @param Data
#---------------------------------------------------------------------
server_handle_numerics() {
	# Slight sanity check
	if [[ "$2" != "$server_nick_current" ]]; then
		log_warning 'Own nick desynced!'
		log_warning "It should be $server_nick_current but server says it is $2"
		log_warning "Correcting own nick and lets hope that doesn't break anything"
		server_nick_current="$2"
	fi
}

#---------------------------------------------------------------------
## Handle NICK messages from server
## @Type Private
## @param Sender
## @param New nick
#---------------------------------------------------------------------
server_handle_nick() {
	local oldnick=
	parse_hostmask_nick "$1" 'oldnick'
	if [[ $oldnick == $server_nick_current ]]; then
		server_nick_current="$2"
	fi
}

#---------------------------------------------------------------------
## Handle nick in use.
## @Type Private
#---------------------------------------------------------------------
server_handle_nick_in_use() {
	if [[ $on_nick -eq 3 ]]; then
		log_error "Third nick is ALSO in use. I give up"
		bot_quit 2
	elif [[ $on_nick -eq 2 ]]; then
		log_warning "Second nick is ALSO in use, trying third"
		send_nick "$config_thirdnick"
		server_nick_current="$config_thirdnick"
		on_nick=3
	else
		log_info_stdout "First nick is in use, trying second"
		send_nick "$config_secondnick"
		on_nick=2
		# FIXME: THIS IS HACKISH AND MAY BREAK
		server_nick_current="$config_secondnick"
	fi
	sleep 1
}

#---------------------------------------------------------------------
## Connect to IRC server.
## @Type Private
#---------------------------------------------------------------------
server_connect() {
	server_connected=0
	on_nick=1
	# Clear current channels:
	channels_current=""
	# HACK: Clean up if we are aborted, replaced after connect with one that sends QUIT
	trap 'transport_disconnect; rm -rvf "$tmp_home"; exit 1' TERM INT
	log_info_stdout "Connecting to \"${config_server}:${config_server_port}\"..."
	transport_connect "$config_server" "$config_server_port" "$config_server_ssl" "$config_server_bind" || return 1
	while true; do
		transport_read_line
		local transport_status="$?"
		# Still connected?
		if ! transport_alive; then
			break
		fi
		# Did we timeout waiting for data
		# or did we get data?
		# We don't care about periodic events here.
		if [[ $transport_status -ne 0 ]]; then
			continue
		fi
		# Check with modules first, needed so we don't skip them.
		for module in $modules_on_connect; do
			module_${module}_on_connect "$line"
		done
		if [[ "$line" =~ ^:[^\ ]+\ +${numeric_RPL_MOTD} ]]; then
			continue
		fi
		log_raw_in "$line"
		if [[ "$line" =~ ^:[^\ ]+\ +([0-9]{3})\ +([^ ]+)\ +(.*) ]]; then
			local numeric="${BASH_REMATCH[1]}"
			# We use this to check below for our own nick.
			local numericnick="${BASH_REMATCH[2]}"
			local data="${BASH_REMATCH[3]}"
			case "$numeric" in
				"$numeric_RPL_MOTDSTART")
					log_info "Motd is not displayed in log";
					;;
				"$numeric_RPL_YOURHOST")
					if [[ $line =~ ^:([^ ]+)  ]]; then # just to get the server name, this should always be true
						server_name="${BASH_REMATCH[1]}"
					fi
					;;
				"$numeric_RPL_WELCOME")
					# This should work
					server_nick_current="$numericnick"
					;;
				# We don't care about these and don't want to show it as unhandled.
				"$numeric_RPL_CREATED"|"$numeric_RPL_LUSERCLIENT"|"$numeric_RPL_LUSEROP"|"$numeric_RPL_LUSERUNKNOWN"|"$numeric_RPL_LUSERCHANNELS"|"$numeric_RPL_LUSERME"|"$numeric_RPL_LOCALUSERS"|"$numeric_RPL_GLOBALUSERS"|"$numeric_RPL_STATSCONN")
					continue
					;;
				"$numeric_RPL_MYINFO")
					server_004="$data"
					server_004=$(tr -d $'\r\n' <<< "$server_004")  # Get rid of ending newline
					;;
				"$numeric_RPL_ISUPPORT")
					server_005+=" $data"
					server_005=$(tr -d $'\r\n' <<< "$server_005") # Get rid of newlines
					server_005="${server_005/ :are supported by this server/}" # Get rid of :are supported by this server
					server_handle_005 "$line"
					;;
				"$numeric_ERR_NICKNAMEINUSE"|"$numeric_ERR_ERRONEUSNICKNAME")
					server_handle_nick_in_use
					;;
				"$numeric_RPL_ENDOFMOTD"|"$numeric_ERR_NOMOTD")
					sleep 1
					log_info_stdout 'Connected'
					server_connected=1
					break
					;;
				*)
					if [[ -z "${numerics[10#${numeric}]}" ]]; then
						log_info_file unknown_data.log "Unknown numeric during connect: $numeric Data: $data"
					else
						log_info_file unknown_data.log "Known but not handled numeric during connect: $numeric Data: $data"
					fi
					;;
			esac
		fi
		if [[ $line =~ "Looking up your hostname" ]]; then
			log_info_stdout "logging in as $config_firstnick..."
			send_nick "$config_firstnick"
			# FIXME: THIS IS HACKISH AND MAY BREAK
			server_nick_current="$config_firstnick"
			# If a server password is set, send it.
			[[ $config_server_passwd ]] && send_raw_flood "PASS $config_server_passwd"
			send_raw_flood "USER $config_ident 0 * :${config_gecos}"
		fi
		server_handle_ping "$line"
	done
}
