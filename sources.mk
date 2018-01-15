MAIN_SOURCES = \
	main.go \
	meow.go

TEST_SOURCES = \
	meow_test.go

include packaging/sources.mk
OTHER_SOURCES = \
	Makefile \
	sources.mk \
	system_test/meow_test.sh \
	${PACKAGING_SOURCES}
