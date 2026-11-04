# Debug builds for the apps. Include this after ASFLAGS, OBJTARGETDIR and the
# "all" target are defined, and make every object depend on $(FLAGSFILE).
#
# make DEBUG=1 builds a debug build (__DEBUG__). The program fills its BSS
# with a poison byte at startup (see src/asminc/poisonbss.inc) and testInit
# checks that it did. make DEBUG=0, the default, builds without it. A test
# suite's test target always makes a debug build.

DEBUG ?= 0
ifeq ($(DEBUG),1)
ASFLAGS += -D __DEBUG__
endif

# The DEBUG setting the objects were built with. Changing it rebuilds them.
FLAGSFILE = $(OBJTARGETDIR)/debug

$(FLAGSFILE): FORCE | $(OBJTARGETDIR)
	@echo "$(DEBUG)" | cmp -s - $@ || echo "$(DEBUG)" > $@

FORCE:
