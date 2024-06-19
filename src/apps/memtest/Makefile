SRCDIR := src
OBJDIR := obj
BINDIR := bin
DRVDIR := ../../../drv

PROGRAM := memtest
D81FILE := $(BINDIR)/$(PROGRAM).d81
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := mega65
CC65TARGET = c64
c64_EMUCMD = x64sc -reu -warp -kernal kernal -VICIIdsize +confirmonexit -autostart
c128_EMUCMD = x128 -reu +warp -kernal kernal -VICIIdsize +confirmonexit -autostart
mega65_EMUCMD := xmega65 -besure -8
EMUCMD = $($(TARGET)_EMUCMD)
DRVFILE = $(DRVDIR)/$(TARGET)-reu.emd

ifdef GCC

SHAREDSRCDIR = ../../shared
CHUNKSSRCDIR = ../../shared/chunks/gnuc
MEMBUFSRCDIR = ../../shared/membuf/gnuc
LIBSRCDIR = ../../lib/common
RUNTIMESRCDIR = ../../lib/runtime/src

else

SHAREDSRCDIR = ../../shared
CHUNKSSRCDIR = ../../shared/chunks
MEMBUFSRCDIR = ../../shared/membuf
LIBSRCDIR = ../../lib/common
RUNTIMESRCDIR = ../../lib/runtime/src

endif

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
ASFLAGS = --asm-include-dir ../../asminc

ifdef GCC
CC = gcc
CFLAGS = $($(TARGET)_CFLAGS) -fpack-struct=1 -m32 -c -D COMPILERTEST -D __TEST__ -I ../../include
LDFLAGS = -m32
else
CC = cl65
CFLAGS = $($(TARGET)_CFLAGS) -W error -D COMPILERTEST -D __TEST__ -O -I ../../include -t $(CC65TARGET) -c --create-dep $(@:.o=.d)
LDFLAGS = --mapfile compiler.map -C $(CONFIG) -t $(CC65TARGET) -C $(CONFIG)
endif

SOURCES := $(wildcard $(SRCDIR)/*.c)

ifndef GCC
ifeq ($(TARGET),mega65)
SOURCES += $(wildcard $(SRCDIR)/*.s)
else
SOURCES += $(SRCDIR)/flushcache.s
endif
endif

SOURCES += $(wildcard $(CHUNKSSRCDIR)/*.c)
SOURCES += $(wildcard $(MEMBUFSRCDIR)/*.c)
SOURCES += $(SHAREDSRCDIR)/tests.c

ifndef GCC
SOURCES += $(wildcard $(CHUNKSSRCDIR)/*.s)
SOURCES += $(wildcard $(MEMBUFSRCDIR)/*.s)
SOURCES += $(wildcard $(LIBSRCDIR)/*.s)

ifeq ($(TARGET),mega65)
LIBCSRCDIR = ../../mega65-libc/src
SOURCES += $(wildcard $(LIBCSRCDIR)/*.c)
SOURCES += $(wildcard $(LIBCSRCDIR)/*.s)
endif
endif

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINDIR) $(OBJDIR) $(D81FILE)

$(BINDIR):
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

vpath %.c $(SRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath %.c $(SHAREDSRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS) -o $@ $<

vpath %.c $(CHUNKSSRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	$(CC)$(CFLAGS) -o $@ $<

vpath %.c $(MEMBUFSRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS) -o $@ $<

ifndef GCC
vpath %.s $(SRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(SHAREDSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(CHUNKSSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(MEMBUFSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

vpath %.s $(RUNTIMESRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

ifeq ($(TARGET),mega65)
vpath %.c $(LIBCSRCDIR)
$(OBJDIR)/%.o: %.c | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(LIBCSRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	cl65 -t $(CC65TARGET) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<
endif
endif

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) $(OBJECTS)

ifeq ($(TARGET),mega65)
$(D81FILE): $(BINDIR)/$(PROGRAM)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM)
else
$(D81FILE): $(BINDIR)/$(PROGRAM)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(BINDIR)/$(PROGRAM) $(PROGRAM) \
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
