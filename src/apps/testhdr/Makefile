CONFIG := testhdr.cfg

SRCDIR := src
OBJDIR := obj
BINDIR := bin
PARSERTESTDIR := ../parsertest
HDRSHAREDDIR := ../../shared/hdr
HDRDIR := ../../lib/hdr
TOKENIZERDIR := ../../overlays/tokenizerasm
PARSERDIR := ../../overlays/parserasm
DUMPASTDIR := ../../overlays/dumpast
MEMINFODIR := ../../overlays/meminfo
ASMLIBDIR := ../../lib/asmlib

PROGRAM := testhdr
TARGET := mega65

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)
D81FILE = $(BINTARGETDIR)/$(PROGRAM).d81

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
TOKENIZER = ../../overlays/tokenizerasm/bin/$(TARGET)/tokenizer
PARSER = ../../overlays/parserasm/bin/$(TARGET)/parser
DUMPAST = ../../overlays/dumpast/bin/$(TARGET)/dumpast
MEMINFO = ../../overlays/meminfo/bin/$(TARGET)/meminfo
PRGFILE = $(BINTARGETDIR)/$(PROGRAM)

# Library units under test. Each needs a .pas file and a .hdr file on the disk.
LIBUNITS := system screen sprites spritemove time
LIBPETSCII := $(addsuffix .petscii,$(LIBUNITS))
HDRFILES := $(addprefix $(HDRDIR)/,$(addsuffix .hdr,$(LIBUNITS)))

BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(DUMPAST)
BINFILES += $(MEMINFO)
BINFILES += $(ASMLIB)
BINFILES += $(PRGFILE)

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

# testhdr shares startup, overlay loading, and error logging code with parsertest
SHAREDSRC := initlib initparser inittokenizer initdumpast initmeminfo loadaddr \
	loadfile logerror m65hdr
SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addprefix $(OBJTARGETDIR)/,$(addsuffix .o,$(SHAREDSRC) hdrload hdrtables))

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

$(DUMPAST): FORCE
	cd $(DUMPASTDIR) && $(MAKE) TARGET=$(TARGET)

$(MEMINFO): FORCE
	cd $(MEMINFODIR) && $(MAKE) TARGET=$(TARGET)

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

vpath %.s $(SRCDIR) $(PARSERTESTDIR)/src $(HDRSHAREDDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C $(CONFIG) $(OBJECTS)

FORCE:

# The disk holds the library sources and their pre-compiled headers.
# Generate the headers with mkhdr and copy them to src/lib/hdr first.
$(D81FILE): $(BINFILES) $(TXTFILES) $(HDRFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(PRGFILE) testhdr,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(PARSER) parser,prg \
	-write $(DUMPAST) dumpast,prg \
	-write $(MEMINFO) meminfo,prg \
	-write $(ASMLIB) asm.lib,prg \
	-write errormsgs.petscii errormsgs.txt,seq \
	$(foreach u,$(LIBUNITS),-write $(u).petscii $(u).pas,seq -write $(HDRDIR)/$(u).hdr $(u).hdr,prg)

clean:
	$(RM) $(TXTFILES)
	$(RM) $(OBJECTS)
	$(RM) $(D81FILE)

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m testhdr.d81 -r $(BINTARGETDIR)/testhdr
