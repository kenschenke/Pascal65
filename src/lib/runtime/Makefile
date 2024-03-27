SRCDIR := src
OBJDIR := obj
BINDIR := bin
LIBCOMMONDIR := ../common

PROGRAM := runtime
CC65TARGET = c64

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)
PRGFILE := $(BINTARGETDIR)/$(PROGRAM)

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
ifeq ($(TARGET),mega65)
ASFLAGS = -I ../../asminc -D RUNTIME -D __MEGA65__
else
ASFLAGS = -I ../../asminc -D RUNTIME
endif
LDFLAGS = --mapfile runtime.map

SOURCES += $(SRCDIR)/abs.s
SOURCES += $(SRCDIR)/add.s
SOURCES += $(SRCDIR)/addysp.s
SOURCES += $(SRCDIR)/array.s
SOURCES += $(SRCDIR)/assign.s
SOURCES += $(SRCDIR)/clearinputbuf.s
SOURCES += $(SRCDIR)/comp.s
SOURCES += $(SRCDIR)/converttypes.s
SOURCES += $(SRCDIR)/decsp4.s
SOURCES += $(SRCDIR)/divide.s
SOURCES += $(SRCDIR)/divint.s
SOURCES += $(SRCDIR)/exit.s
SOURCES += $(SRCDIR)/fileio.s
SOURCES += $(SRCDIR)/float.s
SOURCES += $(SRCDIR)/floatabs.s
SOURCES += $(SRCDIR)/floatadd.s
SOURCES += $(SRCDIR)/floatcomp.s
SOURCES += $(SRCDIR)/floatdiv.s
SOURCES += $(SRCDIR)/floatinput.s
SOURCES += $(SRCDIR)/floatmult.s
SOURCES += $(SRCDIR)/floatneg.s
SOURCES += $(SRCDIR)/floatnorm.s
SOURCES += $(SRCDIR)/floatoutput.s
SOURCES += $(SRCDIR)/floatround.s
SOURCES += $(SRCDIR)/floatsqr.s
SOURCES += $(SRCDIR)/floatsub.s
SOURCES += $(SRCDIR)/floatutil.s
SOURCES += $(SRCDIR)/getkey.s
SOURCES += $(SRCDIR)/getline.s
SOURCES += $(SRCDIR)/incsp4.s
SOURCES += $(SRCDIR)/inputbuf.s
SOURCES += $(SRCDIR)/int8.s
SOURCES += $(SRCDIR)/int8add.s
SOURCES += $(SRCDIR)/int8comp.s
SOURCES += $(SRCDIR)/int8div.s
SOURCES += $(SRCDIR)/int8mult.s
SOURCES += $(SRCDIR)/int8sub.s
SOURCES += $(SRCDIR)/int16.s
SOURCES += $(SRCDIR)/int16add.s
SOURCES += $(SRCDIR)/int16comp.s
SOURCES += $(SRCDIR)/int16div.s
SOURCES += $(SRCDIR)/int16mult.s
SOURCES += $(SRCDIR)/int16sub.s
SOURCES += $(SRCDIR)/int32.s
SOURCES += $(SRCDIR)/int32add.s
SOURCES += $(SRCDIR)/int32comp.s
SOURCES += $(SRCDIR)/int32div.s
SOURCES += $(SRCDIR)/int32mult.s
SOURCES += $(SRCDIR)/int32sqr.s
SOURCES += $(SRCDIR)/int32sub.s
SOURCES += $(SRCDIR)/isalpha.s
SOURCES += $(SRCDIR)/jmptbl.s
SOURCES += $(SRCDIR)/leftpad.s
SOURCES += $(SRCDIR)/loadaddr.s
SOURCES += $(SRCDIR)/math.s
SOURCES += $(SRCDIR)/memcopy.s
SOURCES += $(SRCDIR)/memheap.s
SOURCES += $(SRCDIR)/mod.s
SOURCES += $(SRCDIR)/multiply.s
SOURCES += $(SRCDIR)/negate.s
SOURCES += $(SRCDIR)/popax.s
SOURCES += $(SRCDIR)/popeax.s
SOURCES += $(SRCDIR)/pred.s
SOURCES += $(SRCDIR)/printz.s
SOURCES += $(SRCDIR)/pushax.s
SOURCES += $(SRCDIR)/pusheax.s
SOURCES += $(SRCDIR)/readfloatfrominput.s
SOURCES += $(SRCDIR)/readintfrominput.s
SOURCES += $(SRCDIR)/readint16.s
SOURCES += $(SRCDIR)/readint32.s
SOURCES += $(SRCDIR)/record.s
SOURCES += $(SRCDIR)/rterror.s
SOURCES += $(SRCDIR)/rtstack.s
SOURCES += $(SRCDIR)/sqr.s
SOURCES += $(SRCDIR)/strassign.s
SOURCES += $(SRCDIR)/strcase.s
SOURCES += $(SRCDIR)/strcompare.s
SOURCES += $(SRCDIR)/strconcat.s
SOURCES += $(SRCDIR)/strconvert.s
SOURCES += $(SRCDIR)/strinput.s
SOURCES += $(SRCDIR)/strsubscript.s
SOURCES += $(SRCDIR)/strtofloat.s
SOURCES += $(SRCDIR)/subtract.s
SOURCES += $(SRCDIR)/succ.s
SOURCES += $(SRCDIR)/tenstable.s
SOURCES += $(SRCDIR)/trim.s
SOURCES += $(SRCDIR)/uint16comp.s
SOURCES += $(SRCDIR)/uint16mult.s
SOURCES += $(SRCDIR)/uint32comp.s
SOURCES += $(SRCDIR)/uint32mult.s
SOURCES += $(SRCDIR)/writebool.s
SOURCES += $(SRCDIR)/writechar.s
SOURCES += $(SRCDIR)/writeint.s
SOURCES += $(SRCDIR)/writestring.s
SOURCES += $(SRCDIR)/writetostring.s
SOURCES += $(SRCDIR)/writevalue.s

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINTARGETDIR) $(OBJTARGETDIR) $(PRGFILE)

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(BINTARGETDIR)/$(PROGRAM): $(OBJECTS)
	ld65 $(LDFLAGS) -o $(BINTARGETDIR)/$(PROGRAM) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PRGFILE)
	$(RM) $(BINTARGETDIR)/*
