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
RUNTIMEDIR := src/lib/runtime
SCREENLIBDIR := src/lib/screen
SPRITESDIR := src/lib/sprites
SPRITEMOVEDIR := src/lib/spritemove
SYSTEMLIBDIR := src/lib/system
ASMLIBDIR := src/lib/asmlib
TIMELIBDIR := src/lib/time
TOKENIZERDIR := src/overlays/tokenizerasm
PARSERDIR := src/overlays/parserasm
RESOLVERDIR := src/overlays/resolverasm
TYPECHECKDIR := src/overlays/typecheckasm
EDITOROVLYDIR := src/overlays/editorasm
ICODEDIR := src/overlays/icodeasm
CODEGENDIR := src/overlays/codegenasm
LINKERDIR := src/overlays/linkerasm
COMPILERDIR := src/apps/compilerasm
EDITORAPPDIR := src/apps/editor
MEMINFODIR := src/overlays/meminfo
THEMESDIR := src/overlays/themes
THEMESDAT := src/shared/themes.dat

RUNTIME = $(RUNTIMEDIR)/bin/$(TARGET)/runtime
SCREENLIB = $(SCREENLIBDIR)/bin/$(TARGET)/screen
SPRITESLIB = $(SPRITESDIR)/bin/$(TARGET)/sprites
SPRITEMOVELIB = $(SPRITEMOVEDIR)/bin/$(TARGET)/spritemove
SYSTEMLIB = $(SYSTEMLIBDIR)/bin/$(TARGET)/system
ASMLIB = $(ASMLIBDIR)/bin/$(TARGET)/asmlib
TIMELIB = $(TIMELIBDIR)/bin/$(TARGET)/time
LOADPROG = src/lib/loadprog/bin/$(TARGET)/loadprog
TOKENIZER = $(TOKENIZERDIR)/bin/$(TARGET)/tokenizer
PARSER = $(PARSERDIR)/bin/$(TARGET)/parser
RESOLVER = $(RESOLVERDIR)/bin/$(TARGET)/resolver
TYPECHECK = $(TYPECHECKDIR)/bin/$(TARGET)/typecheck
EDITOROVLY = $(EDITOROVLYDIR)/bin/$(TARGET)/editor
ICODE = $(ICODEDIR)/bin/$(TARGET)/icode
CODEGEN = $(CODEGENDIR)/bin/$(TARGET)/codegen
LINKER = $(LINKERDIR)/bin/$(TARGET)/linker
COMPILER = $(COMPILERDIR)/bin/$(TARGET)/compiler
EDITORAPP = $(EDITORAPPDIR)/bin/$(TARGET)/editor
MEMINFO = $(MEMINFODIR)/bin/$(TARGET)/meminfo
THEMES = $(THEMESDIR)/bin/$(TARGET)/themes

BINFILES := $(EDITORAPP)
BINFILES += $(COMPILER)
BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(SCREENLIB)
BINFILES += $(SPRITESLIB)
BINFILES += $(SPRITEMOVELIB)
BINFILES += $(SYSTEMLIB)
BINFILES += $(LOADPROG)
BINFILES += $(ASMLIB)
BINFILES += $(TIMELIB)
BINFILES += $(RESOLVER)
BINFILES += $(TYPECHECK)
BINFILES += $(ICODE)
BINFILES += $(CODEGEN)
BINFILES += $(LINKER)
BINFILES += $(EDITOROVLY)
BINFILES += $(MEMINFO)
BINFILES += $(THEMES)

TXTFILES := help.petscii title.petscii abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii system.petscii screen.petscii time.petscii screendemo.petscii license.petscii bubbles.petscii sprites.petscii spritemove.petscii

all: $(RUNTIME) editorapp compiler $(SCREENLIB) $(TIMELIB) $(SPRITESLIB) $(SPRITEMOVELIB) $(SYSTEMLIB) $(ASMLIB) $(BINTARGETDIR) $(D81FILE)

help.petscii: src/shared/help.txt
	dos2unix < src/shared/help.txt | petcat -w2 -text -o help.petscii

screen.petscii: $(SCREENLIBDIR)/screen.pas
	dos2unix < $(SCREENLIBDIR)/screen.pas | petcat -w2 -text -o screen.petscii

screendemo.petscii: examples/screendemo.pas
	dos2unix < examples/screendemo.pas | petcat -w2 -text -o screendemo.petscii

time.petscii: $(TIMELIBDIR)/time.pas
	dos2unix < $(TIMELIBDIR)/time.pas | petcat -w2 -text -o time.petscii

bubbles.petscii: examples/bubbles.pas
	dos2unix < examples/bubbles.pas | petcat -w2 -text -o bubbles.petscii

sprites.petscii: $(SPRITESDIR)/sprites.pas
	dos2unix < $(SPRITESDIR)/sprites.pas | petcat -w2 -text -o sprites.petscii

spritemove.petscii: $(SPRITEMOVEDIR)/spritemove.pas
	dos2unix < $(SPRITEMOVEDIR)/spritemove.pas | petcat -w2 -text -o spritemove.petscii

system.petscii: $(SYSTEMLIBDIR)/system.pas
	dos2unix < $(SYSTEMLIBDIR)/system.pas | petcat -w2 -text -o system.petscii

title.petscii: src/shared/title.txt
	dos2unix < src/shared/title.txt | petcat -w2 -text -o title.petscii

license.petscii: license
	dos2unix < license | petcat -w2 -text -o license.petscii

$(RUNTIME):
	cd $(RUNTIMEDIR) && $(MAKE) TARGET=$(TARGET)

abortmsgs.petscii: src/shared/abortmsgs.txt
	dos2unix < src/shared/abortmsgs.txt | petcat -w2 -text -o abortmsgs.petscii

errormsgs.petscii: src/shared/errormsgs.txt
	dos2unix < src/shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

runtimemsgs.petscii: src/shared/runtimemsgs.txt
	dos2unix < src/shared/runtimemsgs.txt | petcat -w2 -text -o runtimemsgs.petscii

$(LOADPROG):
	cd src/lib/loadprog && $(MAKE) TARGET=$(TARGET)

editorapp:
	cd $(EDITORAPPDIR) && $(MAKE) TARGET=$(TARGET)

compiler:
	cd $(COMPILERDIR) && $(MAKE) TARGET=$(TARGET)

$(SCREENLIB):
	cd $(SCREENLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(SPRITESLIB):
	cd $(SPRITESDIR) && $(MAKE) TARGET=$(TARGET)

$(SPRITEMOVELIB):
	cd $(SPRITEMOVEDIR) && $(MAKE) TARGET=$(TARGET)

$(SYSTEMLIB):
	cd $(SYSTEMLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(TIMELIB):
	cd $(TIMELIBDIR) && $(MAKE) TARGET=$(TARGET)

$(ASMLIB):
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(TOKENIZER): FORCE
	cd $(TOKENIZERDIR) && $(MAKE) TARGET=$(TARGET)

$(PARSER): FORCE
	cd $(PARSERDIR) && $(MAKE) TARGET=$(TARGET)

$(RESOLVER): FORCE
	cd $(RESOLVERDIR) && $(MAKE) TARGET=$(TARGET)

$(TYPECHECK): FORCE
	cd $(TYPECHECKDIR) && $(MAKE) TARGET=$(TARGET)

$(ICODE): FORCE
	cd $(ICODEDIR) && $(MAKE) TARGET=$(TARGET)

$(CODEGEN): FORCE
	cd $(CODEGENDIR) && $(MAKE) TARGET=$(TARGET)

$(LINKER): FORCE
	cd $(LINKERDIR) && $(MAKE) TARGET=$(TARGET)

$(EDITOROVLY): FORCE
	cd $(EDITOROVLYDIR) && $(MAKE) TARGET=$(TARGET)

$(MEMINFO): FORCE
	cd $(MEMINFODIR) && $(MAKE) TARGET=$(TARGET)

$(THEMES): FORCE
	cd $(THEMESDIR) && $(MAKE) TARGET=$(TARGET)

FORCE:

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

ifneq ($(TARGET),mega65)
DRVWRITE := -write $(DRVFILE) $(TARGET)-reu.emd
endif

$(D81FILE): $(BINFILES) $(TXTFILES) $(THEMESDAT)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(EDITORAPP) pascal65,prg \
	-write $(COMPILER) compiler,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(PARSER) parser,prg \
	-write $(RESOLVER) resolver,prg \
	-write $(TYPECHECK) typecheck,prg \
	-write $(ICODE) icode,prg \
	-write $(CODEGEN) codegen,prg \
	-write $(LINKER) linker,prg \
	-write $(MEMINFO) meminfo,prg \
	-write $(EDITOROVLY) editor,prg \
	-write $(THEMES) themes,prg \
	-write $(RUNTIME) runtime,prg \
	-write $(SCREENLIB) screen.lib,prg \
	-write $(SPRITESLIB) sprites.lib,prg \
	-write $(SPRITEMOVELIB) spritemove.lib,prg \
	-write $(SYSTEMLIB) system.lib,prg \
	-write $(ASMLIB) asm.lib,prg \
	-write $(TIMELIB) time.lib,prg \
	$(DRVWRITE) \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs.txt,seq \
	-write src/lib/loadprog/bin/$(TARGET)/loadprog loadprog,prg \
	-write help.petscii help.txt,seq \
	-write screen.petscii screen.pas,seq \
	-write screendemo.petscii screendemo.pas,seq \
	-write time.petscii time.pas,seq \
	-write bubbles.petscii bubbles.pas,seq \
	-write sprites.petscii sprites.pas,seq \
	-write spritemove.petscii spritemove.pas,seq \
	-write system.petscii system.pas,seq \
	-write title.petscii title.txt,seq \
	-write license.petscii license.txt,seq \
	-write $(THEMESDAT) themes.dat,seq \
	-write $(THEMESDAT) themes.def,seq

clean:
	cd src/apps && $(MAKE) TARGET=$(TARGET) clean
	cd src/lib && $(MAKE) TARGET=$(TARGET) clean
	$(RM) $(TXTFILES)
	$(RM) $(D81FILE)

run: $(RUNTIME) editorapp compiler $(SYSTEMLIB) $(SCREENLIB) $(ASMLIB) $(SPRITESLIB) $(SPRITEMOVELIB) $(BINTARGETDIR) $(D81FILE)
	$(EMUCMD) $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m pascal65.d81 -r src/apps/editor/bin/$(TARGET)/editor
