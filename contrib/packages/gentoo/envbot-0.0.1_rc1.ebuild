# Copyright 2007 Arvid Norlander
# Distributed under the terms of the GNU General Public License v3
# $Header$

DESCRIPTION="An advanced modular IRC bot coded in bash"
HOMEPAGE="http://envbot.org"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE="bc bugzilla eix gnutls netcat socat ssl sqlite3 contrib"

DEPEND=">=app-shells/bash-3.2"
RDEPEND="${DEPEND}
	openssl? ( dev-libs/openssl )
	gnutls? ( net-libs/gnutls )
	netcat? ( || ( net-analyzer/gnu-netcat net-analyzer/netcat net-analyzer/netcat6 ) )
	eix? ( >=app-portage/eix-0.9.10 )
	bc? ( sys-devel/bc )
	bugzilla? ( >=www-client/pybugz-0.7.1 )
	sqlite3? ( >=dev-db/sqlite-3 )"

S=${WORKDIR}/${P/_/-}

src_compile() {
	# Copy and remove modules as needed according to useflags
	use contrib && {
		cp contrib/modules/m_{eval,helloworld}.sh modules || die "Copying contrib modules failed"
	}
	use bc && { cp contrib/modules/m_calc.sh modules || die "Copying bc module failed"; }
	use eix && { cp contrib/modules/m_eix.sh modules || die "Copying eix module failed"; }
	use bugzilla && { cp contrib/modules/m_bugzilla.sh modules || die "Copying bugzilla module failed"; }
	use sqlite3 || { rm modules/m_{sqlite3,factoids,seen}.sh || die "Removing sqlite3 dependant modules failed"; }
	# Remove transports if support isn't installed
	use netcat || { rm transport/netcat.sh || die "Removing netcat dependant transport failed"; }
	use gnutls || { rm transport/gnutls.sh || die "Removing gnutls dependant transport failed"; }
	use openssl || { rm transport/openssl.sh || die "Removing openssl dependant transport failed"; }
	use socat || { rm transport/socat.sh || die "Removing socat dependant transport failed"; }
	emake || die "make failed"
}

src_install() {
	emake install DESTDIR="${D}" PREFIX="/usr" CONFDIR="/etc" || die "make install failed"
}
