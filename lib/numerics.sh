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

###########################################################################
#                                                                         #
# WARNING THIS FILE IS AUTOGENERATED. ANY CHANGES WILL BE OVERWRITTEN!    #
# See the source in tools/numerics.txt for comments about some numerics   #
# This file was generated with tools/build_numerics.sh                    #
#                                                                         #
###########################################################################

# This file contains a list of numerics that we currently use.
# It is therefore incomplete.

##########################
# Name -> number mapping #
##########################

# During connect, these are sent. They are NOT part of RFC 1459.
# For some format of the parameters varies between servers.
numeric_RPL_WELCOME='001'  # "Welcome to <network>"
numeric_RPL_YOURHOST='002' # "Your host is <servername>, running version <ver>"
numeric_RPL_MYINFO='004'   # "<servername> <version> <available user modes> <available channel modes>"
numeric_RPL_ISUPPORT='005' # Not in any RFC. See http://www.irc.org/tech_docs/005.html for incomplete list.

# "Normal" numerics.
numeric_RPL_LUSERCLIENT='251'
numeric_RPL_LUSEROP='252'
numeric_RPL_LUSERUNKNOWN='253'
numeric_RPL_LUSERCHANNELS='254'
numeric_RPL_LUSERME='255'
numeric_RPL_LOCALUSERS='265'
numeric_RPL_GLOBALUSERS='266'
numeric_RPL_TOPIC='332'
numeric_RPL_TOPICWHOTIME='333'
numeric_RPL_NAMREPLY='353'
numeric_RPL_ENDOFNAMES='366'
numeric_RPL_MOTD='372'
numeric_RPL_MOTDSTART='375'
numeric_RPL_ENDOFMOTD='376'
numeric_RPL_HOSTHIDDEN='396'
numeric_ERR_UNKNOWNCOMMAND='421'
numeric_ERR_ERRONEUSNICKNAME='432'
numeric_ERR_NICKNAMEINUSE='433'
numeric_ERR_NEEDMOREPARAMS='461'
numeric_ERR_UNKNOWNMODE='472'
numeric_ERR_INVITEONLYCHAN='473'
numeric_ERR_BANNEDFROMCHAN='474'

##########################
# Number -> name mapping #
##########################

# During connect, these are sent. They are NOT part of RFC 1459.
# For some format of the parameters varies between servers.
numeric[001]='RPL_WELCOME'  # "Welcome to <network>"
numeric[002]='RPL_YOURHOST' # "Your host is <servername>, running version <ver>"
numeric[004]='RPL_MYINFO'   # "<servername> <version> <available user modes> <available channel modes>"
numeric[005]='RPL_ISUPPORT' # Not in any RFC. See http://www.irc.org/tech_docs/005.html for incomplete list.

# "Normal" numerics.
numeric[251]='RPL_LUSERCLIENT'
numeric[252]='RPL_LUSEROP'
numeric[253]='RPL_LUSERUNKNOWN'
numeric[254]='RPL_LUSERCHANNELS'
numeric[255]='RPL_LUSERME'
numeric[265]='RPL_LOCALUSERS'
numeric[266]='RPL_GLOBALUSERS'
numeric[332]='RPL_TOPIC'
numeric[333]='RPL_TOPICWHOTIME'
numeric[353]='RPL_NAMREPLY'
numeric[366]='RPL_ENDOFNAMES'
numeric[372]='RPL_MOTD'
numeric[375]='RPL_MOTDSTART'
numeric[376]='RPL_ENDOFMOTD'
numeric[396]='RPL_HOSTHIDDEN'
numeric[421]='ERR_UNKNOWNCOMMAND'
numeric[432]='ERR_ERRONEUSNICKNAME'
numeric[433]='ERR_NICKNAMEINUSE'
numeric[461]='ERR_NEEDMOREPARAMS'
numeric[472]='ERR_UNKNOWNMODE'
numeric[473]='ERR_INVITEONLYCHAN'
numeric[474]='ERR_BANNEDFROMCHAN'

# End of generated file.