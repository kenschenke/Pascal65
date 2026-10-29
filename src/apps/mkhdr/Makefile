CONFIG := mkhdr.cfg

SRCDIR := src
OBJDIR := obj
BINDIR := bin
COMPILERDIR := ../compilerasm
HDRSHAREDDIR := ../../shared/hdr
TOKENIZERDIR := ../../overlays/tokenizerasm
PARSERDIR := ../../overlays/parserasm
ASMLIBDIR := ../../lib/asmlib

PROGRAM := mkhdr
TARGET := mega65

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)
D81FILE = $(BINTARGETDIR)/$(PROGRAM).d81

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
TOKENIZER = ../../overlays/tokenizerasm/bin/$(TARGET)/tokenizer
PARSER = ../../overlays/parserasm/bin/$(TARGET)/parser
PRGFILE = $(BINTARGETDIR)/$(PROGRAM)

# Library units to convert. Each one needs a <unit>.pas on the mkhdr disk.
LIBPAS = ../../lib/system/system.pas \
	../../lib/screen/screen.pas \
	../../lib/sprites/sprites.pas \
	../../lib/spritemove/spritemove.pas \
	../../lib/time/time.pas
LIBPETSCII = system.petscii screen.petscii sprites.petscii spritemove.petscii time.petscii

BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(ASMLIB)
BINFILES += $(PRGFILE)

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

# mkhdr shares the compiler's startup, loader, and error logging code
SHAREDSRC := backupZeroPage initlib loadfile inittokenizer initparser keybuf \
	logerror m65hdr loadaddr sourcefn
SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addprefix $(OBJTARGETDIR)/,$(addsuffix .o,$(SHAREDSRC) hdrtables))

TXTFILES := errormsgs.petscii $(LIBPETSCII)

all: $(BINTARGETDIR) $(OBJTARGETDIR) $(PRGFILE) $(D81FILE)

errormsgs.petscii: ../../shared/errormsgs.txt
	dos2unix < ../../shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

system.petscii: ../../lib/system/system.pas
	dos2unix < $< | petcat -w2 -text -o $@

screen.petscii: ../../lib/screen/screen.pas
	dos2unix < $< | petcat -w2 -text -o $@

sprites.petscii: ../../lib/sprites/sprites.pas
	dos2unix < $< | petcat -w2 -text -o $@

spritemove.petscii: ../../lib/spritemove/spritemove.pas
	dos2unix < $< | petcat -w2 -text -o $@

time.petscii: ../../lib/time/time.pas
	dos2unix < $< | petcat -w2 -text -o $@

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

$(TOKENIZER): FORCE
	cd $(TOKENIZERDIR) && $(MAKE) TARGET=$(TARGET)

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

vpath %.s $(SRCDIR) $(COMPILERDIR)/src $(HDRSHAREDDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C $(CONFIG) $(OBJECTS)

FORCE:

# The disk holds mkhdr, its overlays, and the library sources. Run mkhdr
# on it once for each unit (source file "system.pas", and so on), then copy the
# resulting .hdr files to the compiler disk.
$(D81FILE): $(BINFILES) $(TXTFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(PRGFILE) mkhdr,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(PARSER) parser,prg \
	-write $(ASMLIB) asm.lib,prg \
	-write errormsgs.petscii errormsgs.txt,seq \
	-write system.petscii system.pas,seq \
	-write screen.petscii screen.pas,seq \
	-write sprites.petscii sprites.pas,seq \
	-write spritemove.petscii spritemove.pas,seq \
	-write time.petscii time.pas,seq

clean:
	$(RM) $(TXTFILES)
	$(RM) $(OBJECTS)
	$(RM) $(D81FILE)

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m mkhdr.d81 -r $(BINTARGETDIR)/mkhdr
