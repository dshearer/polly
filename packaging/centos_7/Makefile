include ../head.mk

PKGREL = 1
PLATFORM = x86_64

# RPMs don't allow hyphens in version numbers
RPM_VERSION = ${shell echo ${VERSION} | sed -e 's/\-/_/'}

# required by tail.mk:
PKGFILE = polly-${VERSION}-${PKGREL}.el7.centos.${PLATFORM}.rpm
PKGFILE_DEPS = polly.spec
PKGFILE_VM_PATH = polly-${VERSION}-${PKGREL}.el7.centos.${PLATFORM}.rpm
PACKAGING_SUBDIR = centos_7
INSTALL_PKG_CMD = sudo yum install -y ${PKGFILE}
UNINSTALL_PKG_CMD = sudo yum remove -y polly
SRC_TARBALL = polly-${RPM_VERSION}.tgz
SRC_TARBALL_DIR = polly-${RPM_VERSION}

.PHONY : pkg-local
pkg-local : polly.spec ${WORK_DIR}/${SRC_TARBALL}
	# make RPM tree
	mkdir -p "${WORK_DIR}" \
		 "${WORK_DIR}/BUILD" \
                 "${WORK_DIR}/RPMS" \
                 "${WORK_DIR}/RPMS/${PLATFORM}" \
                 "${WORK_DIR}/SOURCES" \
                 "${WORK_DIR}/SPECS" \
                 "${WORK_DIR}/SRPMS"
	cp "$<" "${WORK_DIR}/SPECS"
	
	# copy sources
	cp "${WORK_DIR}/${SRC_TARBALL}" "${WORK_DIR}/SOURCES/"
	
	# build RPMs
	cd "${WORK_DIR}/SPECS" && rpmbuild -bb \
		--define "_topdir ${abspath ${WORK_DIR}}" \
		--define "_pkg_version ${VERSION}" \
		--define "_pkg_release ${PKGREL}" \
		--define "_enable_debug_packages 0" \
		"$<"
	mkdir -p "${DESTDIR}"
	find "${WORK_DIR}/RPMS" -name '*.rpm' | xargs cp -t "${DESTDIR}"

include ../tail.mk
