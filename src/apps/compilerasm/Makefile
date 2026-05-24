CONFIG := compilerasm.cfg

SRCDIR := src
OBJDIR := obj
BINDIR := bin
TOKENIZERDIR := ../../overlays/tokenizerasm
ICODEDIR := ../../overlays/icodeasm
PARSERDIR := ../../overlays/parserasm
RESOLVERDIR := ../../overlays/resolverasm
TYPECHECKDIR := ../../overlays/typecheckasm
LINKERDIR := ../../overlays/linkerasm
CODEGENDIR := ../../overlays/codegenasm
MEMINFODIR := ../../overlays/meminfo
ASMLIBDIR := ../../lib/asmlib
SYSTEMLIBDIR := ../../lib/system
RUNTIMEDIR := ../../lib/runtime

PROGRAM := compiler
TARGET := mega65

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)
D81FILE = $(BINTARGETDIR)/$(PROGRAM).d81

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
TOKENIZER = ../../overlays/tokenizerasm/bin/$(TARGET)/tokenizer
PARSER = ../../overlays/parserasm/bin/$(TARGET)/parser
ICODE = ../../overlays/icodeasm/bin/$(TARGET)/icode
RESOLVER = ../../overlays/resolverasm/bin/$(TARGET)/resolver
TYPECHECK = ../../overlays/typecheckasm/bin/$(TARGET)/typecheck
MEMINFO = ../../overlays/meminfo/bin/$(TARGET)/meminfo
CODEGEN = ../../overlays/codegenasm/bin/$(TARGET)/codegen
LINKER = ../../overlays/linkerasm/bin/$(TARGET)/linker
SYSTEMLIB = ../../lib/system/bin/$(TARGET)/system
RUNTIME = ../../lib/runtime/bin/$(TARGET)/runtime
PRGFILE = $(BINTARGETDIR)/$(PROGRAM)
SYSTEMPAS = ../../lib/system/system.pas

BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(ICODE)
BINFILES += $(RESOLVER)
BINFILES += $(TYPECHECK)
BINFILES += $(MEMINFO)
BINFILES += $(ASMLIB)
BINFILES += $(PRGFILE)
BINFILES += $(CODEGEN)
BINFILES += $(LINKER)
BINFILES += $(SYSTEMLIB)
BINFILES += $(RUNTIME)

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

TXTFILES := errormsgs.petscii system.petscii

all: $(BINTARGETDIR) $(OBJTARGETDIR) $(PRGFILE) $(D81FILE)

errormsgs.petscii: ../../shared/errormsgs.txt
	dos2unix < ../../shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

system.petscii: $(SYSTEMPAS)
	dos2unix < $(SYSTEMPAS) | petcat -w2 -text -o system.petscii

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

$(PARSER): FORCE
	cd $(PARSERDIR) && $(MAKE) TARGET=$(TARGET)

$(RESOLVER): FORCE
	cd $(RESOLVERDIR) && $(MAKE) TARGET=$(TARGET)

$(TYPECHECK): FORCE
	cd $(TYPECHECKDIR) && $(MAKE) TARGET=$(TARGET)

$(TOKENIZER): FORCE
	cd $(TOKENIZERDIR) && $(MAKE) TARGET=$(TARGET)

$(ICODE): FORCE
	cd $(ICODEDIR) && $(MAKE) TARGET=$(TARGET)

$(CODEGEN): FORCE
	cd $(CODEGENDIR) && $(MAKE) TARGET=$(TARGET)

$(LINKER): FORCE
	cd $(LINKERDIR) && $(MAKE) TARGET=$(TARGET)

$(MEMINFO): FORCE
	cd $(MEMINFODIR) && $(MAKE) TARGET=$(TARGET)

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(SYSTEMLIB): FORCE
	cd $(SYSTEMLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(RUNTIME): FORCE
	cd $(RUNTIMEDIR) && $(MAKE) TARGET=$(TARGET)

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C $(CONFIG) $(OBJECTS)

FORCE:

$(D81FILE): $(BINFILES) $(TXTFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(PRGFILE) compiler,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(ICODE) icode,prg \
	-write $(PARSER) parser,prg \
	-write $(RESOLVER) resolver,prg \
	-write $(TYPECHECK) typecheck,prg \
	-write $(CODEGEN) codegen,prg \
	-write $(LINKER) linker,prg \
	-write $(MEMINFO) meminfo,prg \
	-write $(ASMLIB) asm.lib,prg \
	-write $(SYSTEMLIB) system.lib,prg \
	-write $(RUNTIME) runtime,prg \
	-write errormsgs.petscii errormsgs.txt,seq \
	-write system.petscii system.pas,seq

clean:
	$(RM) $(TXTFILES)
	$(RM) $(D81FILE)

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m compiler.d81 -r $(BINTARGETDIR)/compiler
