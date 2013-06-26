# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4
PYTHON_DEPEND="2:2.7"

inherit eutils git-2 python

DESCRIPTION="neversearch; tag files"
HOMEPAGE="http://hetgrotebos.org/wiki/neversearch"
SRC_URI=""

EGIT_REPO_URI="git://github.com/MerlijnWajer/neversearch"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE=""


DEPEND="dev-python/pyxattr sys-apps/coreutils[xattr]"
RDEPEND="${DEPEND}"

src_unpack() {
	git-2_src_unpack
}

src_install() {
	exeinto /usr/bin
	doexe tag
}
