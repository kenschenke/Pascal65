BINDIR := bin

PROGRAM := pascal65
D81FILE := $(BINDIR)/$(PROGRAM).d81

BINFILES := $(wildcard src/apps/ide/bin/pascal65*)
BINFILES += $(wildcard src/apps/compiler/bin/compiler*)
BINFILES += $(wildcard src/apps/interpreter/bin/interpreter*)

all: $(D81FILE)

$(D81FILE):
	cd src/apps && $(MAKE) all
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write src/apps/ide/bin/pascal65 pascal65 \
	-write src/apps/ide/bin/pascal65.1 pascal65.1 \
	-write src/apps/ide/bin/pascal65.2 pascal65.2 \
	-write src/apps/compiler/bin/compiler compiler \
	-write src/apps/compiler/bin/compiler.1 compiler.1 \
	-write src/apps/interpreter/bin/interpreter interpreter \
	-write src/apps/interpreter/bin/interpreter.1 interpreter.1

clean:
	cd src/apps && $(MAKE) clean
	$(RM) $(D81FILE)

run: $(D81FILE)
	x64sc -autoload $(D81FILE)
