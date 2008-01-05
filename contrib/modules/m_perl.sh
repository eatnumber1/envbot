#!/bin/bash
# -*- coding: utf-8 -*-
###########################################################################
#                                                                         #
#  envbot - an IRC bot in bash                                            #
#  Copyright (C) 2007  EmErgE <halt.system@gmail.com>                     #
#  Copyright (C) 2007  Vsevolod Kozlov                                    #
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
## Evaluate with perl
## @Dependencies This module depends on perl
## @Dependencies (http://www.perl.org/about.html)
#---------------------------------------------------------------------

module_perl_INIT() {
        modinit_API='2'
        modinit_HOOKS=''
        if ! hash perl > /dev/null 2>&1; then
                log_error "Couldn't find \"perl\" programming language. The perl module depends on it."
                return 1
        fi
        module_perl_write_perl_script

        commands_register "$1" 'perl' || return 1
}

module_perl_UNLOAD() {
         if [[ -e /tmp/safe_eval.pl ]]; then rm /tmp/safe_eval.pl; fi
        return 0
}

module_perl_REHASH() {
        module_perl_write_perl_script
        return 0
}

module_perl_write_perl_script() {
        cat > /tmp/safe_eval.pl << EOF
#!/usr/bin/perl
use strict;
use Safe;

my \$expr = shift;

my \$cpt = new Safe;

#Basic variable IO and traversal

\$cpt->permit(':base_core');

my(\$ret) = \$cpt->reval(\$expr);

if(\$@){
        print \$@;
}else{
        print \$ret;
}
EOF

}

module_perl_handler_perl() {
        local sender="$1"
        local channel="$2"
        local sendernick=
        parse_hostmask_nick "$sender" 'sendernick'
        # If it isn't in a channel send message back to person who send it,
        # otherwise send in channel
        if ! [[ $2 =~ ^# ]]; then
                channel="$sendernick"
        fi
        local parameters="$3"

        # Extremely Safe Perl Evaluation
        local myresult="$(perl /tmp/safe_eval.pl "$parameters")"
        send_msg "$channel" "${sendernick}: $myresult"
}
