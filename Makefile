BINDIR := bin
DRVDIR := drv

PROGRAM := pascal65
TARGET := mega65
c64_EMUCMD := x64sc -reu -warp +sound -kernal kernal -VICIIdsize +confirmonexit -autostart
mega65_EMUCMD := xmega65 -besure -8
EMUCMD = $($(TARGET)_EMUCMD)
DRVFILE = $(DRVDIR)/$(TARGET)-reu.emd

BINTARGETDIR := $(BINDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

RUNTIME = src/lib/runtime/bin/$(TARGET)/runtime
SCREENLIB = src/lib/screen/bin/$(TARGET)/screen
SPRITESLIB = src/lib/sprites/bin/$(TARGET)/sprites
SPRITEMOVELIB = src/lib/spritemove/bin/$(TARGET)/spritemove
SYSTEMLIB = src/lib/system/bin/$(TARGET)/system
DEBUGLIB = src/lib/debug/bin/$(TARGET)/debug
ASMLIB = src/lib/asmlib/bin/$(TARGET)/asmlib
TIMELIB = src/lib/time/bin/$(TARGET)/time
LOADPROG = src/lib/loadprog/bin/$(TARGET)/loadprog

BINFILES := $(wildcard src/apps/editor/bin/$(TARGET)/editor*)
BINFILES += $(wildcard src/apps/compiler/bin/$(TARGET)/compiler*)
BINFILES += $(SCREENLIB)
BINFILES += $(SPRITESLIB)
BINFILES += $(SPRITEMOVELIB)
BINFILES += $(SYSTEMLIB)
BINFILES += $(LOADPROG)
BINFILES += $(DEBUGLIB)
BINFILES += $(ASMLIB)
BINFILES += $(TIMELIB)

TXTFILES := help.petscii title.petscii abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii system.petscii screen.petscii time.petscii screendemo.petscii hello.petscii debug.petscii fivedice.petscii license.petscii bubbles.petscii sprites.petscii spritemove.petscii

all: $(RUNTIME) editor compiler $(SCREENLIB) $(TIMELIB) $(SPRITESLIB) $(SPRITEMOVELIB) $(SYSTEMLIB) $(DEBUGLIB) $(ASMLIB) $(BINTARGETDIR) $(D81FILE)

help.petscii: src/shared/help.txt
	dos2unix < src/shared/help.txt | petcat -w2 -text -o help.petscii

screen.petscii: src/lib/screen/screen.pas
	dos2unix < src/lib/screen/screen.pas | petcat -w2 -text -o screen.petscii

screendemo.petscii: examples/screendemo.pas
	dos2unix < examples/screendemo.pas | petcat -w2 -text -o screendemo.petscii

time.petscii: src/lib/time/time.pas
	dos2unix < src/lib/time/time.pas | petcat -w2 -text -o time.petscii

bubbles.petscii: examples/bubbles.pas
	dos2unix < examples/bubbles.pas | petcat -w2 -text -o bubbles.petscii

fivedice.petscii: examples/fivedice.pas
	dos2unix < examples/fivedice.pas | petcat -w2 -text -o fivedice.petscii

hello.petscii: hello.pas
	dos2unix < hello.pas | petcat -w2 -text -o hello.petscii

sprites.petscii: src/lib/sprites/sprites.pas
	dos2unix < src/lib/sprites/sprites.pas | petcat -w2 -text -o sprites.petscii

spritemove.petscii: src/lib/spritemove/spritemove.pas
	dos2unix < src/lib/spritemove/spritemove.pas | petcat -w2 -text -o spritemove.petscii

system.petscii: src/lib/system/system.pas
	dos2unix < src/lib/system/system.pas | petcat -w2 -text -o system.petscii

debug.petscii: src/lib/debug/debug.pas
	dos2unix < src/lib/debug/debug.pas | petcat -w2 -text -o debug.petscii

title.petscii: src/shared/title.txt
	dos2unix < src/shared/title.txt | petcat -w2 -text -o title.petscii

license.petscii: license
	dos2unix < license | petcat -w2 -text -o license.petscii

$(RUNTIME):
	cd src/lib/runtime && $(MAKE) TARGET=$(TARGET)

abortmsgs.petscii: src/shared/abortmsgs.txt
	dos2unix < src/shared/abortmsgs.txt | petcat -w2 -text -o abortmsgs.petscii

errormsgs.petscii: src/shared/errormsgs.txt
	dos2unix < src/shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

runtimemsgs.petscii: src/shared/runtimemsgs.txt
	dos2unix < src/shared/runtimemsgs.txt | petcat -w2 -text -o runtimemsgs.petscii

$(LOADPROG):
	cd src/lib/loadprog && $(MAKE) TARGET=$(TARGET)

editor:
	cd src/apps/editor && $(MAKE) TARGET=$(TARGET)

compiler:
	cd src/apps/compiler && $(MAKE) TARGET=$(TARGET)

$(SCREENLIB):
	cd src/lib/screen && $(MAKE) TARGET=$(TARGET)

$(SPRITESLIB):
	cd src/lib/sprites && $(MAKE) TARGET=$(TARGET)

$(SPRITEMOVELIB):
	cd src/lib/spritemove && $(MAKE) TARGET=$(TARGET)

$(SYSTEMLIB):
	cd src/lib/system && $(MAKE) TARGET=$(TARGET)

$(TIMELIB):
	cd src/lib/time && $(MAKE) TARGET=$(TARGET)

$(DEBUGLIB):
	cd src/lib/debug && $(MAKE) TARGET=$(TARGET)

$(ASMLIB):
	cd src/lib/asmlib && $(MAKE) TARGET=$(TARGET)

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

ifneq ($(TARGET),mega65)
DRVWRITE := -write $(DRVFILE) $(TARGET)-reu.emd
endif

$(D81FILE): $(BINFILES) $(TXTFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write src/apps/editor/bin/$(TARGET)/editor pascal65,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler compiler,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.1 compiler.1,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.2 compiler.2,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.3 compiler.3,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.4 compiler.4,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.5 compiler.5,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.6 compiler.6,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.7 compiler.7,prg \
	-write src/lib/runtime/bin/$(TARGET)/runtime runtime,prg \
	-write src/lib/screen/bin/$(TARGET)/screen screen.lib,prg \
	-write src/lib/sprites/bin/$(TARGET)/sprites sprites.lib,prg \
	-write src/lib/spritemove/bin/$(TARGET)/spritemove spritemove.lib,prg \
	-write src/lib/system/bin/$(TARGET)/system system.lib,prg \
	-write src/lib/asmlib/bin/$(TARGET)/asmlib asm.lib,prg \
	-write src/lib/time/bin/$(TARGET)/time time.lib,prg \
	$(DRVWRITE) \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write src/lib/loadprog/bin/$(TARGET)/loadprog loadprog,prg \
	-write help.petscii help.txt,seq \
	-write screen.petscii screen.pas,seq \
	-write screendemo.petscii screendemo.pas,seq \
	-write time.petscii time.pas,seq \
	-write bubbles.petscii bubbles.pas,seq \
	-write fivedice.petscii fivedice.pas,seq \
	-write sprites.petscii sprites.pas,seq \
	-write spritemove.petscii spritemove.pas,seq \
	-write system.petscii system.pas,seq \
	-write title.petscii title.txt,seq \
	-write license.petscii license.txt,seq

clean:
	cd src/apps && $(MAKE) TARGET=$(TARGET) clean
	cd src/lib && $(MAKE) TARGET=$(TARGET) clean
	$(RM) $(TXTFILES)
	$(RM) $(D81FILE)

run: $(RUNTIME) editor compiler $(SYSTEMLIB) $(SCREENLIB) $(ASMLIB) $(SPRITESLIB) $(SPRITEMOVELIB) $(BINTARGETDIR) $(D81FILE)
	$(EMUCMD) $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m pascal65.d81 -r src/apps/editor/bin/$(TARGET)/editor
