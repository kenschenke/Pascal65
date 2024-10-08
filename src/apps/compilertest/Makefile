SRCDIR := src
OBJDIR := obj
BINDIR := bin
DRVDIR := ../../../drv
TOKENIZEROVRLSRC := ../../overlays/tokenizer
PARSEROVRLSRC := ../../overlays/parser
RESOLVEROVRLSRC := ../../overlays/resolver
TYPECHECKOVRLSRC := ../../overlays/typecheck
ICODEOVRLSRC := ../../overlays/icode
ICODEGENOVRLSRC := ../../overlays/icodegen
LINKEROVRLSRC := ../../overlays/linker
SHAREDSRCDIR = ../../shared
SHAREDCODEGENDIR = $(SHAREDSRCDIR)/codegen
LIBCSRCDIR = ../../mega65-libc/src
LIBCOMMONDIR = ../../lib/common
TARGETSRCDIR = $(SRCDIR)/$(TARGET)
RUNTIME = ../../lib/runtime/bin/$(TARGET)/runtime
SCREENLIB = ../../lib/screen/bin/$(TARGET)/screen
SYSTEMLIB = ../../lib/system/bin/$(TARGET)/system
DEMOLIB = ../../lib/demolib/bin/$(TARGET)/demolib

ifdef GCC

SHAREDCHUNKSDIR = $(SHAREDSRCDIR)/chunks/gnuc
SHAREDMEMBUFDIR = $(SHAREDSRCDIR)/membuf/gnuc

else

SHAREDCHUNKSDIR = $(SHAREDSRCDIR)/chunks
SHAREDMEMBUFDIR = $(SHAREDSRCDIR)/membuf

endif

PROGRAM := compilertest
D81FILE := $(BINDIR)/$(PROGRAM).d81
TOKENIZEROVRLFILE := $(PROGRAM).1
PARSEROVRLFILE := $(PROGRAM).2
RESOLVEROVRLFILE := $(PROGRAM).3
TYPECHECKOVRLFILE := $(PROGRAM).4
ICODEOVRLFILE := $(PROGRAM).5
ICODEGENOVRLFILE := $(PROGRAM).6
LINKEROVRLFILE := $(PROGRAM).7
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := mega65
CC65TARGET = c64
c64_EMUCMD = x64sc -reu -warp +sound -kernal kernal -VICIIdsize +confirmonexit -autostart
c128_EMUCMD = x128 -reu -warp -kernal kernal -VICIIdsize +confirmonexit -autostart
mega65_EMUCMD := xmega65 -besure -8
EMUCMD = $($(TARGET)_EMUCMD)
DRVFILE = $(DRVDIR)/$(TARGET)-reu.emd

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
CONFIG := cfg-$(TARGET).cfg
ASFLAGS = --asm-include-dir ../../asminc

ifdef GCC
CC = gcc
CFLAGS = $($(TARGET)_CFLAGS) -c -fpack-struct=1 -m32 -D COMPILERTEST -I ../../include
LDFLAGS = -m32
else
CC = cl65
CFLAGS = $($(TARGET)_CFLAGS) -W error -D COMPILERTEST -O -I ../../include -t $(CC65TARGET) -c --create-dep $(@:.o=.d)
LDFLAGS = --mapfile compiler.map -C $(CONFIG) -t $(CC65TARGET)
endif

SOURCES := $(wildcard $(SRCDIR)/*.c)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.c)
SOURCES += $(wildcard $(SHAREDSRCDIR)/*.c)
SOURCES += $(wildcard $(SHAREDCHUNKSDIR)/*.c)
SOURCES += $(wildcard $(SHAREDMEMBUFDIR)/*.c)
SOURCES += $(wildcard $(SHAREDCODEGENDIR)/*.c)
TOKENIZEROVRLSRCS := $(wildcard $(TOKENIZEROVRLSRC)/*.c)
TOKENIZEROVRLSRCS += $(wildcard $(TOKENIZEROVRLSRC)/*.s)
PARSEROVRLSRCS := $(wildcard $(PARSEROVRLSRC)/*.c)
PARSEROVRLSRCS += $(wildcard $(PARSEROVRLSRC)/*.s)
RESOLVEROVRLSRCS := $(wildcard $(RESOLVEROVRLSRC)/*.c)
TYPECHECKOVRLSRCS := $(wildcard $(TYPECHECKOVRLSRC)/*.c)
ICODEOVRLSRCS := $(wildcard $(ICODEOVRLSRC)/*.c)
ICODEGENOVRLSRCS := $(wildcard $(ICODEGENOVRLSRC)/*.c)
LINKEROVRLSRCS := $(wildcard $(LINKEROVRLSRC)/*.c)

ifdef GCC
SOURCES += $(wildcard $(SHAREDSRCDIR)/gnuc/*.c)
endif

ifndef GCC

ifeq ($(TARGET),mega65)
SOURCES += $(LIBCSRCDIR)/memory.c
endif

SOURCES += $(wildcard $(SRCDIR)/*.s)
SOURCES += $(wildcard $(TARGETSRCDIR)/*.s)
SOURCES += $(wildcard $(SHAREDSRCDIR)/*.s)
SOURCES += $(wildcard $(SHAREDCHUNKSDIR)/*.s)
SOURCES += $(wildcard $(SHAREDMEMBUFDIR)/*.s)
SOURCES += $(wildcard $(SHAREDCODEGENDIR)/*.s)
SOURCES += $(wildcard $(LIBCOMMONDIR)/*.s)

endif

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(TOKENIZEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(PARSEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(RESOLVEROVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(TYPECHECKOVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(ICODEOVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(ICODEGENOVRLSRCS)))))
OBJECTS += $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(LINKEROVRLSRCS)))))

TXTFILES := abortmsgs.petscii errormsgs.petscii runtimemsgs.petscii system.petscii stdroutines.petscii strroutines.petscii strtests.petscii ifthen.petscii loops.petscii recarray.petscii scopetest.petscii varinit.petscii vartest.petscii casetest.petscii procfunc.petscii add.petscii subtract.petscii multiply.petscii divint.petscii unit.petscii unit1.petscii assign.petscii bitwise.petscii demolib.petscii libtest.petscii trig.petscii filetesta.petscii filetestb.petscii pointers.petscii rtnptrs.petscii

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINDIR) $(OBJDIR) $(D81FILE)

$(BINDIR):
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

vpath %.c $(SRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath %.s $(SRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(TARGETSRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath %.s $(TARGETSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

ifdef GCC

vpath $(TOKENIZEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(TOKENIZEROVRLSRC)/%.c | $(OBJDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(PARSEROVRLSRC)/%.c | $(OBJDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(RESOLVEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(RESOLVEROVRLSRC)/%.c | $(OBJDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(TYPECHECKOVRLSRC)/%.c
$(OBJDIR)/%.o: $(TYPECHECKOVRLSRC)/%.c | $(OBJDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(ICODEOVRLSRC)/%.c
$(OBJDIR)/%.o: $(ICODEOVRLSRC)/%.c | $(OBJDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(ICODEGENOVRLSRC)/%.c
$(OBJDIR)/%.o: $(ICODEGENOVRLSRC)/%.c | $(OBJDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(LINKEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(LINKEROVRLSRC)/%.c | $(OBJDIR)
	gcc $(CFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/gnuc/%.c
$(OBJDIR)/%.o: $(SHAREDSRCDIR)/gnuc/%.c | $(OBJDIR)
	$(CC) $(CFLAGS) -o $@ $<

else

vpath $(TOKENIZEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(TOKENIZEROVRLSRC)/%.c | $(OBJDIR)
	cl65 --code-name OVERLAY1 $(CFLAGS) -o $@ $<

vpath $(TOKENIZEROVRLSRC)/%.s
$(OBJDIR)/%.o: $(TOKENIZEROVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY1 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(PARSEROVRLSRC)/%.c | $(OBJDIR)
	cl65 --code-name OVERLAY2 $(CFLAGS) -o $@ $<

vpath $(PARSEROVRLSRC)/%.s
$(OBJDIR)/%.o: $(PARSEROVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY2 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(RESOLVEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(RESOLVEROVRLSRC)/%.c | $(OBJDIR)
	cl65 --code-name OVERLAY3 $(CFLAGS) -o $@ $<

vpath $(RESOLVEROVRLSRC)/%.s
$(OBJDIR)/%.o: $(RESOLVEROVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY3 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(TYPECHECKOVRLSRC)/%.c
$(OBJDIR)/%.o: $(TYPECHECKOVRLSRC)/%.c | $(OBJDIR)
	cl65 --code-name OVERLAY4 $(CFLAGS) -o $@ $<

vpath $(TYPECHECKOVRLSRC)/%.s
$(OBJDIR)/%.o: $(TYPECHECKOVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY4 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(ICODEOVRLSRC)/%.c
$(OBJDIR)/%.o: $(ICODEOVRLSRC)/%.c | $(OBJDIR)
	cl65 --code-name OVERLAY5 $(CFLAGS) -o $@ $<

vpath $(ICODEOVRLSRC)/%.s
$(OBJDIR)/%.o: $(ICODEOVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY5 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(ICODEGENOVRLSRC)/%.c
$(OBJDIR)/%.o: $(ICODEGENOVRLSRC)/%.c | $(OBJDIR)
	cl65 --code-name OVERLAY6 $(CFLAGS) -o $@ $<

vpath $(ICODEGENOVRLSRC)/%.s
$(OBJDIR)/%.o: $(ICODEGENOVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY6 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(LINKEROVRLSRC)/%.c
$(OBJDIR)/%.o: $(LINKEROVRLSRC)/%.c | $(OBJDIR)
	cl65 --code-name OVERLAY7 $(CFLAGS) -o $@ $<

vpath $(LINKEROVRLSRC)/%.s
$(OBJDIR)/%.o: $(LINKEROVRLSRC)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) --code-name OVERLAY7 -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

endif  # end of else ifdef GCC

vpath $(LIBCSRCDIR)/%.c
$(OBJDIR)/%.o: $(LIBCSRCDIR)/%.c | $(OBJDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath $(LIBCSRCDIR)/%.s
$(OBJDIR)/%.o: $(LIBCSRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/%.c
$(OBJDIR)/%.o: $(SHAREDSRCDIR)/%.c | $(OBJDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath $(SHAREDSRCDIR)/%.s
$(OBJDIR)/%.o: $(SHAREDSRCDIR)/%.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDCHUNKSDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDCHUNKSDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDMEMBUFDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDMEMBUFDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.c $(SHAREDCODEGENDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath %.s $(SHAREDCODEGENDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBCOMMONDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

abortmsgs.petscii: $(SHAREDSRCDIR)/abortmsgs.txt
	dos2unix < $(SHAREDSRCDIR)/abortmsgs.txt | petcat -w2 -text -o abortmsgs.petscii

errormsgs.petscii: $(SHAREDSRCDIR)/errormsgs.txt
	dos2unix < $(SHAREDSRCDIR)/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

runtimemsgs.petscii: $(SHAREDSRCDIR)/runtimemsgs.txt
	dos2unix < $(SHAREDSRCDIR)/runtimemsgs.txt | petcat -w2 -text -o runtimemsgs.petscii

add.petscii: add.pas
	dos2unix < add.pas | petcat -w2 -text -o add.petscii

assign.petscii: assign.pas
	dos2unix < assign.pas | petcat -w2 -text -o assign.petscii

bitwise.petscii: bitwise.pas
	dos2unix < bitwise.pas | petcat -w2 -text -o bitwise.petscii

libtest.petscii: libtest.pas
	dos2unix < libtest.pas | petcat -w2 -text -o libtest.petscii

ifthen.petscii: ifthen.pas
	dos2unix < ifthen.pas | petcat -w2 -text -o ifthen.petscii

loops.petscii: loops.pas
	dos2unix < loops.pas | petcat -w2 -text -o loops.petscii

stdroutines.petscii: stdroutines.pas
	dos2unix < stdroutines.pas | petcat -w2 -text -o stdroutines.petscii

strroutines.petscii: strroutines.pas
	dos2unix < strroutines.pas | petcat -w2 -text -o strroutines.petscii

strtests.petscii: strtests.pas
	dos2unix < strtests.pas | petcat -w2 -text -o strtests.petscii

recarray.petscii: recarray.pas
	dos2unix < recarray.pas | petcat -w2 -text -o recarray.petscii

scopetest.petscii: scopetest.pas
	dos2unix < scopetest.pas | petcat -w2 -text -o scopetest.petscii

varinit.petscii: varinit.pas
	dos2unix < varinit.pas | petcat -w2 -text -o varinit.petscii

vartest.petscii: vartest.pas
	dos2unix < vartest.pas | petcat -w2 -text -o vartest.petscii

casetest.petscii: casetest.pas
	dos2unix < casetest.pas | petcat -w2 -text -o casetest.petscii

procfunc.petscii: procfunc.pas
	dos2unix < procfunc.pas | petcat -w2 -text -o procfunc.petscii

multiply.petscii: multiply.pas
	dos2unix < multiply.pas | petcat -w2 -text -o multiply.petscii

divint.petscii: divint.pas
	dos2unix < divint.pas | petcat -w2 -text -o divint.petscii

subtract.petscii: subtract.pas
	dos2unix < subtract.pas | petcat -w2 -text -o subtract.petscii

system.petscii: ../../lib/system/system.pas
	dos2unix < ../../lib/system/system.pas | petcat -w2 -text -o system.petscii

demolib.petscii: ../../lib/demolib/demolib.pas
	dos2unix < ../../lib/demolib/demolib.pas | petcat -w2 -text -o demolib.petscii

trig.petscii: trig.pas
	dos2unix < trig.pas | petcat -w2 -text -o trig.petscii

filetesta.petscii: filetesta.pas
	dos2unix < filetesta.pas | petcat -w2 -text -o filetesta.petscii

filetestb.petscii: filetestb.pas
	dos2unix < filetestb.pas | petcat -w2 -text -o filetestb.petscii

pointers.petscii: pointers.pas
	dos2unix < pointers.pas | petcat -w2 -text -o pointers.petscii

rtnptrs.petscii: rtnptrs.pas
	dos2unix < rtnptrs.pas | petcat -w2 -text -o rtnptrs.petscii

unit.petscii: unit.pas
	dos2unix < unit.pas | petcat -w2 -text -o unit.petscii

unit1.petscii: unit1.pas
	dos2unix < unit1.pas | petcat -w2 -text -o unit1.petscii

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) $(OBJECTS)

ifdef GCC
$(D81FILE): $(BINDIR)/$(PROGRAM)
else ifeq ($(TARGET),mega65)
$(D81FILE): $(BINDIR)/$(PROGRAM) $(RUNTIME) $(SYSTEMLIB) $(DEMOLIB) $(TXTFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write $(BINDIR)/$(TOKENIZEROVRLFILE) $(TOKENIZEROVRLFILE) \
	-write $(BINDIR)/$(PARSEROVRLFILE) $(PARSEROVRLFILE) \
	-write $(BINDIR)/$(RESOLVEROVRLFILE) $(RESOLVEROVRLFILE) \
	-write $(BINDIR)/$(TYPECHECKOVRLFILE) $(TYPECHECKOVRLFILE) \
	-write $(BINDIR)/$(ICODEOVRLFILE) $(ICODEOVRLFILE) \
	-write $(BINDIR)/$(ICODEGENOVRLFILE) $(ICODEGENOVRLFILE) \
	-write $(BINDIR)/$(LINKEROVRLFILE) $(LINKEROVRLFILE) \
	-write $(RUNTIME) runtime \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write runtimemsgs.petscii runtimemsgs,seq \
	-write add.petscii add.pas,seq \
	-write assign.petscii assign.pas,seq \
	-write bitwise.petscii bitwise.pas,seq \
	-write libtest.petscii libtest.pas,seq \
	-write stdroutines.petscii stdroutines.pas,seq \
	-write strroutines.petscii strroutines.pas,seq \
	-write strtests.petscii strtests.pas,seq \
	-write ifthen.petscii ifthen.pas,seq \
	-write loops.petscii loops.pas,seq \
	-write recarray.petscii recarray.pas,seq \
	-write scopetest.petscii scopetest.pas,seq \
	-write varinit.petscii varinit.pas,seq \
	-write vartest.petscii vartest.pas,seq \
	-write casetest.petscii casetest.pas,seq \
	-write procfunc.petscii procfunc.pas,seq \
	-write multiply.petscii multiply.pas,seq \
	-write divint.petscii divint.pas,seq \
	-write subtract.petscii subtract.pas,seq \
	-write filetesta.petscii filetesta.pas,seq \
	-write filetestb.petscii filetestb.pas,seq \
	-write pointers.petscii pointers.pas,seq \
	-write rtnptrs.petscii rtnptrs.pas,seq \
	-write system.petscii system.pas,seq \
	-write trig.petscii trig.pas,seq \
	-write demolib.petscii demolib.pas,seq \
	-write $(SYSTEMLIB) system.lib,prg \
	-write $(DEMOLIB) demolib.lib,prg \
	-write unit.petscii unit.pas,seq \
	-write unit1.petscii unit1.pas,seq
else
$(D81FILE): $(BINDIR)/$(PROGRAM) $(RUNTIME) $(SYSTEMLIB) $(DEMOLIB) $(TXTFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
	-write $(BINDIR)/$(TOKENIZEROVRLFILE) $(TOKENIZEROVRLFILE) \
	-write $(BINDIR)/$(PARSEROVRLFILE) $(PARSEROVRLFILE) \
	-write $(BINDIR)/$(RESOLVEROVRLFILE) $(RESOLVEROVRLFILE) \
	-write $(BINDIR)/$(TYPECHECKOVRLFILE) $(TYPECHECKOVRLFILE) \
	-write $(BINDIR)/$(ICODEOVRLFILE) $(ICODEOVRLFILE) \
	-write $(BINDIR)/$(ICODEGENOVRLFILE) $(ICODEGENOVRLFILE) \
	-write $(BINDIR)/$(LINKEROVRLFILE) $(LINKEROVRLFILE) \
	-write $(RUNTIME) runtime \
	-write abortmsgs.petscii abortmsgs,seq \
	-write errormsgs.petscii errormsgs,seq \
	-write add.petscii add.pas,seq \
	-write assign.petscii assign.pas,seq \
	-write bitwise.petscii bitwise.pas,seq \
	-write libtest.petscii libtest.pas,seq \
	-write runtimemsgs.petscii runtimemsgs,seq \
	-write stdroutines.petscii stdroutines.pas,seq \
	-write strroutines.petscii strroutines.pas,seq \
	-write strtests.petscii strtests.pas,seq \
	-write ifthen.petscii ifthen.pas,seq \
	-write loops.petscii loops.pas,seq \
	-write recarray.petscii recarray.pas,seq \
	-write scopetest.petscii scopetest.pas,seq \
	-write varinit.petscii varinit.pas,seq \
	-write vartest.petscii vartest.pas,seq \
	-write casetest.petscii casetest.pas,seq \
	-write procfunc.petscii procfunc.pas,seq \
	-write multiply.petscii multiply.pas,seq \
	-write divint.petscii divint.pas,seq \
	-write subtract.petscii subtract.pas,seq \
	-write filetesta.petscii filetesta.pas,seq \
	-write filetestb.petscii filetestb.pas,seq \
	-write pointers.petscii pointers.pas,seq \
	-write rtnptrs.petscii rtnptrs.pas,seq \
	-write system.petscii system.pas,seq \
	-write demolib.petscii demolib.pas,seq \
	-write $(SYSTEMLIB) system.lib,prg \
	-write $(DEMOLIB) demolib.lib,prg \
	-write unit.petscii unit.pas,seq \
	-write unit1.petscii unit1.pas,seq \
	-write $(DRVFILE) $(TARGET)-reu.emd,prg
endif

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINDIR)/*
	$(RM) $(D81FILE)

run: $(D81FILE)
	$(EMUCMD) $<
