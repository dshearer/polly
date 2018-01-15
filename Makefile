PROGRAM_PATH = github.com/dshearer/polly

# Where polly will be installed:
prefix = /usr/local
bindir = ${prefix}/bin

# Don't futz around with 'GOPATH' in your packaging scripts -- take care of it here
GO_WKSPC ?= ${abspath ../../../..}
GO = GOPATH=${GO_WKSPC} go

# Used when making source tarball
SRC_TARBALL = polly.tgz
SRC_TARBALL_DIR = polly

# Define 'MAIN_SOURCES', 'TEST_SOURCES', and 'OTHER_SOURCES'
include sources.mk
ALL_SOURCES = \
	${MAIN_SOURCES} \
	${TEST_SOURCES} \
	${OTHER_SOURCES}

###############################################################################
# Build
###############################################################################
.PHONY : build
build : ${GO_WKSPC}/bin/polly

${GO_WKSPC}/bin/polly : ${MAIN_SOURCES}
	${GO} install ${PROGRAM_PATH}

###############################################################################
# Test
###############################################################################
.PHONY : check
check : ${TEST_SOURCES}
	${GO} test ${PROGRAM_PATH}

###############################################################################
# Install
###############################################################################
.PHONY : install
install : ${DESTDIR}${bindir}/polly

${DESTDIR}${bindir}/polly : ${GO_WKSPC}/bin/polly
	mkdir -p "${dir $@}"
	cp "$<" "$@"

###############################################################################
# Make source tarball
###############################################################################
.PHONY : dist
dist :
	echo ${ALL_SOURCES}
	mkdir -p "${DESTDIR}dist-tmp/${SRC_TARBALL_DIR}"
	rsync -a --relative ${ALL_SOURCES} "${DESTDIR}dist-tmp/${SRC_TARBALL_DIR}"
	tar -C "${DESTDIR}dist-tmp" -czf "${DESTDIR}${SRC_TARBALL}" \
				"${SRC_TARBALL_DIR}"
	rm -rf "${DESTDIR}dist-tmp"

###############################################################################
# Clean
###############################################################################
.PHONY : clean
clean :
	${GO} clean -i ${PROGRAM_PATH}
	rm -f "${DESTDIR}${SRC_TARBALL}"
