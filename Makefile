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
RUNTIMELIB = src/lib/runtimelib/bin/$(TARGET)/runtime.lib
SYSTEMLIB = src/lib/system/bin/$(TARGET)/system
LOADPROG = src/lib/loadprog/bin/$(TARGET)/loadprog

BINFILES := $(wildcard src/apps/ide/bin/$(TARGET)/pascal65*)
BINFILES += $(wildcard src/apps/compiler/bin/$(TARGET)/compiler*)
BINFILES += $(SYSTEMLIB)
BINFILES += $(LOADPROG)

TXTFILES := runtime.petscii help.petscii title.petscii abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii

all: $(RUNTIME) $(RUNTIMELIB) ide compiler $(SYSTEMLIB) $(BINTARGETDIR) $(D81FILE)

help.petscii: src/shared/help.txt
	dos2unix < src/shared/help.txt | petcat -w2 -text -o help.petscii

title.petscii: src/shared/title.txt
	dos2unix < src/shared/title.txt | petcat -w2 -text -o title.petscii

$(RUNTIME):
	cd src/lib/runtime && $(MAKE) TARGET=$(TARGET)

$(RUNTIMELIB):
	cd src/lib/runtimelib && $(MAKE) TARGET=$(TARGET)

runtime.petscii: src/shared/runtime.def
	dos2unix < src/shared/runtime.def | petcat -w2 -text -o runtime.petscii

abortmsgs.petscii: src/shared/abortmsgs.txt
	dos2unix < src/shared/abortmsgs.txt | petcat -w2 -text -o abortmsgs.petscii

errormsgs.petscii: src/shared/errormsgs.txt
	dos2unix < src/shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

runtimemsgs.petscii: src/shared/runtimemsgs.txt
	dos2unix < src/shared/runtimemsgs.txt | petcat -w2 -text -o runtimemsgs.petscii

$(LOADPROG):
	cd src/lib/loadprog && $(MAKE) TARGET=$(TARGET)

ide:
	cd src/apps/ide && $(MAKE) TARGET=$(TARGET)

compiler:
	cd src/apps/compiler && $(MAKE) TARGET=$(TARGET)

$(SYSTEMLIB):
	cd src/lib/system && $(MAKE) TARGET=$(TARGET)

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

ifneq ($(TARGET),mega65)
DRVWRITE := -write $(DRVFILE) $(TARGET)-reu.emd
endif

$(D81FILE): $(BINFILES) $(TXTFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write src/apps/ide/bin/$(TARGET)/pascal65 pascal65,prg \
	-write src/apps/ide/bin/$(TARGET)/pascal65.1 pascal65.1,prg \
	-write src/apps/ide/bin/$(TARGET)/pascal65.2 pascal65.2,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler compiler,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.1 compiler.1,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.2 compiler.2,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.3 compiler.3,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.4 compiler.4,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.5 compiler.5,prg \
	-write src/apps/compiler/bin/$(TARGET)/compiler.6 compiler.6,prg \
	-write src/lib/runtime/bin/$(TARGET)/runtime runtime,prg \
	-write src/lib/runtimelib/bin/$(TARGET)/runtime.lib runtime.lib,prg \
	-write src/lib/system/system.pas system.pas,seq \
	-write src/lib/system/bin/$(TARGET)/system system.lib,prg \
	$(DRVWRITE) \
	-write runtime.petscii runtime.def,seq \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write runtimemsgs.petscii runtimemsgs,seq \
	-write src/lib/loadprog/bin/$(TARGET)/loadprog loadprog,prg \
	-write help.petscii help.txt,seq \
	-write title.petscii title.txt,seq \

clean:
	cd src/apps && $(MAKE) TARGET=$(TARGET) clean
	cd src/lib && $(MAKE) TARGET=$(TARGET) clean
	$(RM) $(TXTFILES)
	$(RM) $(D81FILE)

run: $(RUNTIME) $(RUNTIMELIB) ide compiler $(SYSTEMLIB) $(BINTARGETDIR) $(D81FILE)
	$(EMUCMD) $(D81FILE)
