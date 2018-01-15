include ../head.mk

VERSION = 1.0

# required by tail.mk:
PKGFILE = polly_${VERSION}-1_amd64.deb
PKGFILE_DEPS = $(wildcard debian-pkg/**)
PKGFILE_VM_PATH = polly_${VERSION}-1_amd64.deb
PACKAGING_SUBDIR = debian_9
INSTALL_PKG_CMD = sudo dpkg -i ${PKGFILE}
UNINSTALL_PKG_CMD = sudo dpkg -r polly

.PHONY : pkg-local
pkg-local : ${WORK_DIR}/${SRC_TARBALL}
	cp "${WORK_DIR}/${SRC_TARBALL}" \
		"${SRC_ROOT}/../polly_${VERSION}.orig.tar.gz"
	cp -R debian-pkg "${SRC_ROOT}/debian"
	cd "${SRC_ROOT}" && dpkg-buildpackage -us -uc
	mkdir -p "${DESTDIR}/"
	mv "${SRC_ROOT}"/../*.deb "${DESTDIR}/"

include ../tail.mk
