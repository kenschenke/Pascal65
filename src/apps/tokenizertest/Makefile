BINDIR := bin
OBJDIR := obj
SRCDIR := src
DRVDIR := drv

PROGRAM := tokenizertest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
TOKENIZER = ../../overlays/tokenizerasm/bin/$(TARGET)/tokenizer
PRGFILE = $(BINTARGETDIR)/tokenizertest

BINFILES += $(TOKENIZER)
BINFILES += $(ASMLIB)
BINFILES += $(PRGFILE)

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

TXTFILES := test1.petscii test2.petscii test3.petscii test4.petscii test5.petscii errormsgs.petscii

all: $(OBJTARGETDIR) $(BINTARGETDIR) $(PRGFILE) $(D81FILE)

test1.petscii: test1.pas
	dos2unix < test1.pas | petcat -w2 -text -o test1.petscii

test2.petscii: test2.pas
	dos2unix < test2.pas | petcat -w2 -text -o test2.petscii

test3.petscii: test3.pas
	dos2unix < test3.pas | petcat -w2 -text -o test3.petscii

test4.petscii: test4.pas
	dos2unix < test4.pas | petcat -w2 -text -o test4.petscii

test5.petscii: test5.pas
	dos2unix < test5.pas | petcat -w2 -text -o test5.petscii

# abortmsgs.petscii: src/shared/abortmsgs.txt
# 	dos2unix < src/shared/abortmsgs.txt | petcat -w2 -text -o abortmsgs.petscii

errormsgs.petscii: ../../shared/errormsgs.txt
	dos2unix < ../../shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

# runtimemsgs.petscii: src/shared/runtimemsgs.txt
# 	dos2unix < src/shared/runtimemsgs.txt | petcat -w2 -text -o runtimemsgs.petscii

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C tokenizertest.cfg $(OBJECTS)

$(D81FILE): $(BINFILES) $(TXTFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(PRGFILE) tokenizertest,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(ASMLIB) asm.lib,prg \
	-write test1.petscii test1.pas,seq \
	-write test3.petscii test3.pas,seq \
	-write test2.petscii test2.pas,seq \
	-write test4.petscii test4.pas,seq \
	-write test5.petscii test5.pas,seq \
	-write errormsgs.petscii errormsgs.txt,seq

clean:
	$(RM) $(TXTFILES)
	$(RM) $(D81FILE)
	$(RM) $(OBJECTS)

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m tokenizer.d81 -r $(BINTARGETDIR)/tokenizertest
