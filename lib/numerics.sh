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

# All 0xx must be maintained by hand in build_numerics.sh

# During connect, these are sent. They are NOT part of RFC 1459.
# For some format of the parameters varies between servers.
numeric_RPL_WELCOME='001'  # "Welcome to <network>"
numeric_RPL_YOURHOST='002' # "Your host is <servername>, running version <ver>"
numeric_RPL_MYINFO='004'   # "<servername> <version> <available user modes> <available channel modes>"
numeric_RPL_ISUPPORT='005' # Not in any RFC. See http://www.irc.org/tech_docs/005.html for incomplete list.

numeric_RPL_MAP='006'    # Not from any RFC
numeric_RPL_MAPEND='007' # Not from any RFC
# "Normal" numerics.
numeric_RPL_ENDOFSTATS='219'
numeric_RPL_UMODEIS='221'
numeric_RPL_STATSUPTIME='242'
numeric_RPL_LUSERCLIENT='251'
numeric_RPL_LUSEROP='252'
numeric_RPL_LUSERUNKNOWN='253'
numeric_RPL_LUSERCHANNELS='254'
numeric_RPL_LUSERME='255'
numeric_RPL_ADMINME='256'
numeric_RPL_ADMINLOC1='257'
numeric_RPL_ADMINLOC2='258'
numeric_RPL_ADMINEMAIL='259'
numeric_RPL_LOCALUSERS='265'
numeric_RPL_GLOBALUSERS='266'
numeric_RPL_SILELIST='271'
numeric_RPL_ENDOFSILELIST='272'
numeric_RPL_AWAY='301'
numeric_RPL_ISON='303'
numeric_RPL_TEXT='304'
numeric_RPL_UNAWAY='305'
numeric_RPL_UNAWAY='306'
numeric_RPL_WHOISREGNICK='307'
numeric_RPL_WHOISUSER='311'
numeric_RPL_WHOISSERVER='312'
numeric_RPL_WHOISOPERATOR='313'
numeric_RPL_WHOWASUSER='314'
numeric_RPL_ENDOFWHO='315'
numeric_RPL_WHOISIDLE='317'
numeric_RPL_ENDOFWHOIS='318'
numeric_RPL_WHOISCHANNELS='319'
numeric_RPL_WHOISSPECIAL='320'
numeric_RPL_LISTSTART='321'
numeric_RPL_LIST='322'
numeric_RPL_LISTEND='323'
numeric_RPL_CHANNELMODEIS='324'
numeric_RPL_CREATIONTIME='329'
numeric_RPL_WHOISACCOUNT='330'
numeric_RPL_TOPIC='332'
numeric_RPL_TOPICWHOTIME='333'
numeric_RPL_INVITING='341'
numeric_RPL_VERSION='351'
numeric_RPL_WHOREPLY='352'
numeric_RPL_NAMREPLY='353'
numeric_RPL_LINKS='364'
numeric_RPL_ENDOFLINKS='365'
numeric_RPL_ENDOFNAMES='366'
numeric_RPL_BANLIST='367'
numeric_RPL_ENDOFBANLIST='368'
numeric_RPL_ENDOFWHOWAS='369'
numeric_RPL_INFO='371'
numeric_RPL_MOTD='372'
numeric_RPL_ENDOFINFO='374'
numeric_RPL_MOTDSTART='375'
numeric_RPL_ENDOFMOTD='376'
numeric_RPL_WHOISHOST='378'
numeric_RPL_TIME='391'
numeric_RPL_HOSTHIDDEN='396'
numeric_ERR_NOSUCHNICK='401'
numeric_ERR_CANNOTSENDTOCHAN='404'
numeric_ERR_TOOMANYCHANNELS='405'
numeric_ERR_WASNOSUCHNICK='406'
numeric_ERR_UNKNOWNCOMMAND='421'
numeric_ERR_ERRONEUSNICKNAME='432'
numeric_ERR_NICKNAMEINUSE='433'
numeric_ERR_USERONCHANNEL='443'
numeric_ERR_SUMMONDISABLED='445'
numeric_ERR_USERSDISABLED='446'
numeric_ERR_NONICKCHANGE='447'
numeric_ERR_NOTFORHALFOPS='460'
numeric_ERR_NEEDMOREPARAMS='461'
numeric_ERR_ALREADYREGISTERED='462'
numeric_ERR_UNKNOWNMODE='472'
numeric_ERR_INVITEONLYCHAN='473'
numeric_ERR_BANNEDFROMCHAN='474'
numeric_ERR_CANNOTKNOCK='480'
numeric_ERR_NOPRIVILEGES='481'
numeric_ERR_CHANOPRIVSNEEDED='482'
numeric_ERR_ATTACKDENY='484'
numeric_ERR_ALLMUSTUSESSL='490'
numeric_ERR_NOREJOINONKICK='495'
numeric_ERR_CHANOWNPRIVNEEDED='499'
numeric_RPL_LOGON='600'
numeric_RPL_LOGOFF='601'
numeric_RPL_WATCHOFF='602'
numeric_RPL_NOWON='604'
numeric_RPL_NOWOFF='605'
numeric_RPL_WATCHLIST='606'
numeric_RPL_ENDOFWATCHLIST='607'
numeric_RPL_WHOISSECURE='671'
numeric_RPL_COMMANDS='902'
numeric_RPL_ENDOFCOMMANDS='903'

##########################
# Number -> name mapping #
##########################

# All 0xx must be maintained by hand in build_numerics.sh

# During connect, these are sent. They are NOT part of RFC 1459.
# For some format of the parameters varies between servers.
numeric[1]='RPL_WELCOME'  # "Welcome to <network>"
numeric[2]='RPL_YOURHOST' # "Your host is <servername>, running version <ver>"
numeric[4]='RPL_MYINFO'   # "<servername> <version> <available user modes> <available channel modes>"
numeric[5]='RPL_ISUPPORT' # Not in any RFC. See http://www.irc.org/tech_docs/005.html for incomplete list.

numeric[6]='RPL_MAP'    # Not from any RFC
numeric[7]='RPL_MAPEND' # Not from any RFC

# "Normal" numerics.
numeric[219]='RPL_ENDOFSTATS'
numeric[221]='RPL_UMODEIS'
numeric[242]='RPL_STATSUPTIME'
numeric[251]='RPL_LUSERCLIENT'
numeric[252]='RPL_LUSEROP'
numeric[253]='RPL_LUSERUNKNOWN'
numeric[254]='RPL_LUSERCHANNELS'
numeric[255]='RPL_LUSERME'
numeric[256]='RPL_ADMINME'
numeric[257]='RPL_ADMINLOC1'
numeric[258]='RPL_ADMINLOC2'
numeric[259]='RPL_ADMINEMAIL'
numeric[265]='RPL_LOCALUSERS'
numeric[266]='RPL_GLOBALUSERS'
numeric[271]='RPL_SILELIST'
numeric[272]='RPL_ENDOFSILELIST'
numeric[301]='RPL_AWAY'
numeric[303]='RPL_ISON'
numeric[304]='RPL_TEXT'
numeric[305]='RPL_UNAWAY'
numeric[306]='RPL_UNAWAY'
numeric[307]='RPL_WHOISREGNICK'
numeric[311]='RPL_WHOISUSER'
numeric[312]='RPL_WHOISSERVER'
numeric[313]='RPL_WHOISOPERATOR'
numeric[314]='RPL_WHOWASUSER'
numeric[315]='RPL_ENDOFWHO'
numeric[317]='RPL_WHOISIDLE'
numeric[318]='RPL_ENDOFWHOIS'
numeric[319]='RPL_WHOISCHANNELS'
numeric[320]='RPL_WHOISSPECIAL'
numeric[321]='RPL_LISTSTART'
numeric[322]='RPL_LIST'
numeric[323]='RPL_LISTEND'
numeric[324]='RPL_CHANNELMODEIS'
numeric[329]='RPL_CREATIONTIME'
numeric[330]='RPL_WHOISACCOUNT'
numeric[332]='RPL_TOPIC'
numeric[333]='RPL_TOPICWHOTIME'
numeric[341]='RPL_INVITING'
numeric[351]='RPL_VERSION'
numeric[352]='RPL_WHOREPLY'
numeric[353]='RPL_NAMREPLY'
numeric[364]='RPL_LINKS'
numeric[365]='RPL_ENDOFLINKS'
numeric[366]='RPL_ENDOFNAMES'
numeric[367]='RPL_BANLIST'
numeric[368]='RPL_ENDOFBANLIST'
numeric[369]='RPL_ENDOFWHOWAS'
numeric[371]='RPL_INFO'
numeric[372]='RPL_MOTD'
numeric[374]='RPL_ENDOFINFO'
numeric[375]='RPL_MOTDSTART'
numeric[376]='RPL_ENDOFMOTD'
numeric[378]='RPL_WHOISHOST'
numeric[391]='RPL_TIME'
numeric[396]='RPL_HOSTHIDDEN'
numeric[401]='ERR_NOSUCHNICK'
numeric[404]='ERR_CANNOTSENDTOCHAN'
numeric[405]='ERR_TOOMANYCHANNELS'
numeric[406]='ERR_WASNOSUCHNICK'
numeric[421]='ERR_UNKNOWNCOMMAND'
numeric[432]='ERR_ERRONEUSNICKNAME'
numeric[433]='ERR_NICKNAMEINUSE'
numeric[443]='ERR_USERONCHANNEL'
numeric[445]='ERR_SUMMONDISABLED'
numeric[446]='ERR_USERSDISABLED'
numeric[447]='ERR_NONICKCHANGE'
numeric[460]='ERR_NOTFORHALFOPS'
numeric[461]='ERR_NEEDMOREPARAMS'
numeric[462]='ERR_ALREADYREGISTERED'
numeric[472]='ERR_UNKNOWNMODE'
numeric[473]='ERR_INVITEONLYCHAN'
numeric[474]='ERR_BANNEDFROMCHAN'
numeric[480]='ERR_CANNOTKNOCK'
numeric[481]='ERR_NOPRIVILEGES'
numeric[482]='ERR_CHANOPRIVSNEEDED'
numeric[484]='ERR_ATTACKDENY'
numeric[490]='ERR_ALLMUSTUSESSL'
numeric[495]='ERR_NOREJOINONKICK'
numeric[499]='ERR_CHANOWNPRIVNEEDED'
numeric[600]='RPL_LOGON'
numeric[601]='RPL_LOGOFF'
numeric[602]='RPL_WATCHOFF'
numeric[604]='RPL_NOWON'
numeric[605]='RPL_NOWOFF'
numeric[606]='RPL_WATCHLIST'
numeric[607]='RPL_ENDOFWATCHLIST'
numeric[671]='RPL_WHOISSECURE'
numeric[902]='RPL_COMMANDS'
numeric[903]='RPL_ENDOFCOMMANDS'

# End of generated file.
