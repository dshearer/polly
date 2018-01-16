# Must be defined by includers:
#
#	Required variables:
# 		PKGFILE -- name that the resulting package should have
# 		PKGFILE_DEPS -- list of dependencies of the package
# 		PKGFILE_VM_PATH -- path to the package on the VM after
#						   pkg-local is run
#   		PACKAGING_SUBDIR -- name of subdir of packaging dir
#		INSTALL_PKG_CMD -- command to run on VM to install package
#		UNINSTALL_PKG_CMD -- command to run on VM to uninstall package
#
#	Optional variables:
#		SRC_TARBALL -- name that the src tarball should have
#		SRC_TARBALL_DIR -- name that the dir inside the src tarball
#							should have
#
#	Rules:
#		pkg-local

ifndef PKGFILE
${error PKGFILE is undefined}
endif
ifndef PKGFILE_DEPS
${error PKGFILE_DEPS is undefined}
endif
ifndef PKGFILE_VM_PATH
${error PKGFILE_VM_PATH is undefined}
endif
ifndef PACKAGING_SUBDIR
${error PACKAGING_SUBDIR is undefined}
endif
ifndef INSTALL_PKG_CMD
${error INSTALL_PKG_CMD is undefined}
endif
ifndef UNINSTALL_PKG_CMD
${error UNINSTALL_PKG_CMD is undefined}
endif

VAGRANT_SSH = vagrant ssh --no-tty -c

.PHONY : main
main :
	@echo "Choose pkg-local or pkg-vm"

.PHONY : pkg-vm
pkg-vm : .vm-is-running ${DESTDIR}${PKGFILE}	
	# stop VM
	vagrant suspend
	rm -f .vm-is-running

.PHONY : test-vm
test-vm : ${DESTDIR}${PKGFILE}
	# install package
	-${VAGRANT_SSH} "${UNINSTALL_PKG_CMD}"
	vagrant scp "${DESTDIR}${PKGFILE}" ":${PKGFILE}"
	${VAGRANT_SSH} "${INSTALL_PKG_CMD}"

	# run test
	${VAGRANT_SSH} 'make -C ${SRC_TARBALL_DIR}/packaging/${PACKAGING_SUBDIR} test-local'

.PHONY : test-local
test-local :
	"${SRC_ROOT}/system_test/meow_test.sh"

.vm-is-created :
	@# NOTE: We do 'vagrant reload' b/c some packages may need a restart
	@# Why the sleep?  Without it, Debian snapshots were having kernel
	@# crashes.
	(vagrant snapshot list | grep Base >/dev/null) || \
		(vagrant up && vagrant reload && sleep 10 && vagrant snapshot \
			save Base)
	touch $@
	
.vm-is-running : .vm-is-created
	vagrant up
	touch $@

${DESTDIR}${PKGFILE} : Vagrantfile ${WORK_DIR}/${SRC_TARBALL} \
		${PKGFILE_DEPS} .vm-is-running
	
	# copy Jobber source to VM
	vagrant scp "${WORK_DIR}/${SRC_TARBALL}" ":${SRC_TARBALL}"
	${VAGRANT_SSH} "tar -xzmf ${SRC_TARBALL}"
	
	# make Jobber package
	${VAGRANT_SSH} 'mkdir -p work && \
		mv ${SRC_TARBALL} work/${SRC_TARBALL} && \
		mkdir -p dest && \
		make -C ${SRC_TARBALL_DIR}/packaging/${PACKAGING_SUBDIR} \
		pkg-local DESTDIR=$${PWD}/dest/ WORK_DIR=$${PWD}/work'
	
	# copy package out of VM
	vagrant scp :dest/${PKGFILE_VM_PATH} "${DESTDIR}${PKGFILE}"
	
	touch "$@"

.PHONY : ${WORK_DIR}/${SRC_TARBALL}
${WORK_DIR}/${SRC_TARBALL} :
	${MAKE} -C "${SRC_ROOT}" dist "DESTDIR=${WORK_DIR}/" \
		"SRC_TARBALL=${SRC_TARBALL}" "SRC_TARBALL_DIR=${SRC_TARBALL_DIR}"

.PHONY : clean
clean : clean-common
	(vagrant snapshot list | grep Base >/dev/null) && \
		vagrant snapshot restore Base
	-vagrant halt

.PHONY : clean-common
clean-common :
	rm -rf "${WORK_DIR}" "${DESTDIR}${PKGFILE}" \
		.vm-is-running .vm-is-pristine .vm-is-created

.PHONY : deepclean
deepclean : clean-common
	-vagrant destroy -f
	rm -f .vm-is-created
