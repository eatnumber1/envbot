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
# This file is used to generate some, uh, generated files.
# Also some other tasks

ENVBOT_VERSION = 0.0.1

# For make dest-dir, defaults
DISTDIR ?= dist
# For make install, defaults
DESTDIR ?= DEST
PREFIX  ?= /usr/local
BINDIR  ?= $(PREFIX)/bin
CONFDIR ?= $(PREFIX)/etc
LIBDIR  ?= $(PREFIX)/lib
DATADIR ?= $(PREFIX)/share
MANDIR  ?= $(DATADIR)/man
# And now for actual place of stuff
ENVBOT_LIBDIR       ?= $(LIBDIR)/envbot
ENVBOT_TRANSPORTDIR ?= $(ENVBOT_LIBDIR)/transport
ENVBOT_LIBRARYDIR   ?= $(ENVBOT_LIBDIR)/lib
ENVBOT_MODULESDIR   ?= $(ENVBOT_LIBDIR)/modules
ENVBOT_DATADIR      ?= $(DATADIR)/envbot/data
ENVBOT_LOGDIR       ?= $(DATADIR)/envbot/logs
ENVBOT_CONFDIR      ?= $(CONFDIR)/envbot
ENVBOT_DOCDIR       ?= $(DATADIR)/doc/envbot-$(ENVBOT_VERSION)

# Now for some commands
INSTALL ?= install -p
SED     ?= sed
RM      ?= rm

all: numerics config

config:
	$(SED) "s|@@moddir@@|modules|;s|@@transportdir@@|transport|;s|@@datadir@@|data|;s|@@logdir@@|logs|" doc/bot_settings.sh.example.in > bot_settings.sh.example

numerics:
	tools/build_numerics.sh > lib/numerics.sh

# Used by developers to update man page.
man:
	help2man -NS envbot -n 'An advanced modular IRC bot in bash' "/bin/bash envbot" > doc/envbot.1

clean:
	rm -vf *~ */*~ */*/*~ bot_settings.sh.example

cleanlogs:
	rm -vrf logs/*

dist-dir:
	rm -rf $(DISTDIR)
	bzr export $(DISTDIR)

install: all
	@echo "#########################################################################"
	@echo "#                                                                       #"
	@echo "# Installing... Note that running from source directory is recommended! #"
	@echo "#                                                                       #"
	@echo "#########################################################################"
	$(INSTALL) -d $(DESTDIR)$(PREFIX)            $(DESTDIR)$(BINDIR)
	$(INSTALL) -d $(DESTDIR)$(ENVBOT_LIBDIR)     $(DESTDIR)$(ENVBOT_CONFDIR)
	$(INSTALL) -d $(DESTDIR)$(ENVBOT_DATADIR)    $(DESTDIR)$(ENVBOT_TRANSPORTDIR)
	$(INSTALL) -d $(DESTDIR)$(ENVBOT_LIBRARYDIR) $(DESTDIR)$(ENVBOT_MODULESDIR)
	$(INSTALL) -d $(DESTDIR)$(ENVBOT_DOCDIR)     $(DESTDIR)$(MANDIR)/man1
	$(INSTALL) -d $(DESTDIR)$(ENVBOT_LOGDIR)
	$(SED) "s|^library_dir=.*|library_dir='$(ENVBOT_LIBRARYDIR)'|;s|^config_file=.*|config_file='$(ENVBOT_CONFDIR)/bot_settings.sh'|" envbot > envbot.tmp
	$(INSTALL) envbot.tmp                     $(DESTDIR)$(BINDIR)/envbot
	$(RM) envbot.tmp
	$(INSTALL) -m 644 lib/*.sh                $(DESTDIR)$(ENVBOT_LIBRARYDIR)
	$(INSTALL) -m 644 modules/*.sh            $(DESTDIR)$(ENVBOT_MODULESDIR)
	$(INSTALL) -m 644 transport/*.sh          $(DESTDIR)$(ENVBOT_TRANSPORTDIR)
	$(INSTALL) -m 644 README AUTHORS GPL3.txt $(DESTDIR)$(ENVBOT_DOCDIR)
	$(INSTALL) -m 644 doc/*.{sql,txt}         $(DESTDIR)$(ENVBOT_DOCDIR)
	$(INSTALL) -m 644 doc/envbot.1            $(DESTDIR)$(MANDIR)/man1
	$(INSTALL) -m 644 data/{faq.txt.example,quotes.txt.example.pqf} $(DESTDIR)$(ENVBOT_DATADIR)
	$(SED) "s|@@moddir@@|$(ENVBOT_MODULESDIR)|;s|@@transportdir@@|$(ENVBOT_TRANSPORTDIR)|;s|@@datadir@@|$(ENVBOT_DATADIR)|;s|@@logdir@@|$(ENVBOT_LOGDIR)|" doc/bot_settings.sh.example.in > bot_settings.tmp
	$(INSTALL) -m 644 bot_settings.tmp $(DESTDIR)$(ENVBOT_CONFDIR)/bot_settings.sh.example
	$(RM) bot_settings.tmp

.PHONY: all numerics clean cleanlogs dist-dir
