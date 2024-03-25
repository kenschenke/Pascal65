MAKEFLAGS += -r

SRCDIR := src
OBJDIR := obj
BINDIR := bin
CFGDIR := cfg
LIBDIR := lib
LIBCOMMONDIR := ../common
MKRUNTIME := mkruntime.py

LIBNAME := runtime.lib
CC65TARGET = c64

OBJTARGETDIR := $(OBJDIR)/$(TARGET)
BINTARGETDIR := $(BINDIR)/$(TARGET)
LIBTARGETDIR := $(LIBDIR)/$(TARGET)
LIBFILE := $(BINTARGETDIR)/$(LIBNAME)

ifeq ($(TARGET),mega65)
ASFLAGS = -I ../../asminc -D __MEGA65__
else
ASFLAGS = -I ../../asminc
endif
LDFLAGS =

SOURCES += $(wildcard $(SRCDIR)/*.s)

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

LIBS := $(addsuffix .lib,$(basename $(addprefix $(LIBTARGETDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINDIR) $(OBJTARGETDIR) $(LIBTARGETDIR) $(LIBFILE)

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

$(LIBDIR):
	mkdir -p $@

$(LIBTARGETDIR): $(LIBDIR)
	mkdir -p $@

$(OBJTARGETDIR)/abs.o: $(SRCDIR)/abs.s $(CFGDIR)/abs.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/add.o: $(SRCDIR)/add.s $(CFGDIR)/add.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/array.o: $(SRCDIR)/array.s $(CFGDIR)/array.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/assign.o: $(SRCDIR)/assign.s $(CFGDIR)/assign.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/comp.o: $(SRCDIR)/comp.s $(CFGDIR)/comp.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/converttypes.o: $(SRCDIR)/converttypes.s $(CFGDIR)/converttypes.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/decsp4.o: $(SRCDIR)/decsp4.s $(CFGDIR)/decsp4.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/divide.o: $(SRCDIR)/divide.s $(CFGDIR)/divide.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/divint.o: $(SRCDIR)/divint.s $(CFGDIR)/divint.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/float.o: $(SRCDIR)/float.s $(CFGDIR)/float.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatabs.o: $(SRCDIR)/floatabs.s $(CFGDIR)/floatabs.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatadd.o: $(SRCDIR)/floatadd.s $(CFGDIR)/floatadd.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatcomp.o: $(SRCDIR)/floatcomp.s $(CFGDIR)/floatcomp.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatdiv.o: $(SRCDIR)/floatdiv.s $(CFGDIR)/floatdiv.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatinput.o: $(SRCDIR)/floatinput.s $(CFGDIR)/floatinput.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatmult.o: $(SRCDIR)/floatmult.s $(CFGDIR)/floatmult.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatneg.o: $(SRCDIR)/floatneg.s $(CFGDIR)/floatneg.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatnorm.o: $(SRCDIR)/floatnorm.s $(CFGDIR)/floatnorm.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatoutput.o: $(SRCDIR)/floatoutput.s $(CFGDIR)/floatoutput.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatround.o: $(SRCDIR)/floatround.s $(CFGDIR)/floatround.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatsqr.o: $(SRCDIR)/floatsqr.s $(CFGDIR)/floatsqr.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatsub.o: $(SRCDIR)/floatsub.s $(CFGDIR)/floatsub.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/floatutil.o: $(SRCDIR)/floatutil.s $(CFGDIR)/floatutil.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/getline.o: $(SRCDIR)/getline.s $(CFGDIR)/getline.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/inputbuf.o: $(SRCDIR)/inputbuf.s $(CFGDIR)/inputbuf.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int8.o: $(SRCDIR)/int8.s $(CFGDIR)/int8.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int8add.o: $(SRCDIR)/int8add.s $(CFGDIR)/int8add.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int8comp.o: $(SRCDIR)/int8comp.s $(CFGDIR)/int8comp.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int8div.o: $(SRCDIR)/int8div.s $(CFGDIR)/int8div.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int8mult.o: $(SRCDIR)/int8mult.s $(CFGDIR)/int8mult.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int8sub.o: $(SRCDIR)/int8sub.s $(CFGDIR)/int8sub.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int16.o: $(SRCDIR)/int16.s $(CFGDIR)/int16.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int16add.o: $(SRCDIR)/int16add.s $(CFGDIR)/int16add.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int16comp.o: $(SRCDIR)/int16comp.s $(CFGDIR)/int16comp.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int16div.o: $(SRCDIR)/int16div.s $(CFGDIR)/int16div.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int16mult.o: $(SRCDIR)/int16mult.s $(CFGDIR)/int16mult.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int16sub.o: $(SRCDIR)/int16sub.s $(CFGDIR)/int16sub.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int32.o: $(SRCDIR)/int32.s $(CFGDIR)/int32.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int32add.o: $(SRCDIR)/int32add.s $(CFGDIR)/int32add.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int32comp.o: $(SRCDIR)/int32comp.s $(CFGDIR)/int32comp.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int32div.o: $(SRCDIR)/int32div.s $(CFGDIR)/int32div.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int32mult.o: $(SRCDIR)/int32mult.s $(CFGDIR)/int32mult.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int32sqr.o: $(SRCDIR)/int32sqr.s $(CFGDIR)/int32sqr.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/int32sub.o: $(SRCDIR)/int32sub.s $(CFGDIR)/int32sub.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/leftpad.o: $(SRCDIR)/leftpad.s $(CFGDIR)/leftpad.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/mod.o: $(SRCDIR)/mod.s $(CFGDIR)/mod.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/math.o: $(SRCDIR)/math.s $(CFGDIR)/math.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/memcopy.o: $(SRCDIR)/memcopy.s $(CFGDIR)/memcopy.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/multiply.o: $(SRCDIR)/multiply.s $(CFGDIR)/multiply.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/negate.o: $(SRCDIR)/negate.s $(CFGDIR)/negate.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/popax.o: $(SRCDIR)/popax.s $(CFGDIR)/popax.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/pred.o: $(SRCDIR)/pred.s $(CFGDIR)/pred.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/pusheax.o: $(SRCDIR)/pusheax.s $(CFGDIR)/pusheax.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/printz.o: $(SRCDIR)/printz.s $(CFGDIR)/printz.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/readfloatfrominput.o: $(SRCDIR)/readfloatfrominput.s $(CFGDIR)/readfloatfrominput.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/readint16.o: $(SRCDIR)/readint16.s $(CFGDIR)/readint16.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/readint32.o: $(SRCDIR)/readint32.s $(CFGDIR)/readint32.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/readintfrominput.o: $(SRCDIR)/readintfrominput.s $(CFGDIR)/readintfrominput.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/record.o: $(SRCDIR)/record.s $(CFGDIR)/record.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/rtstack.o: $(SRCDIR)/rtstack.s $(CFGDIR)/rtstack.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/sqr.o: $(SRCDIR)/sqr.s $(CFGDIR)/sqr.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/string.o: $(SRCDIR)/string.s $(CFGDIR)/string.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/strassign.o: $(SRCDIR)/strassign.s $(CFGDIR)/strassign.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/strconcat.o: $(SRCDIR)/strconcat.s $(CFGDIR)/strconcat.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/strconvert.o: $(SRCDIR)/strconvert.s $(CFGDIR)/strconvert.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/strinput.o: $(SRCDIR)/strinput.s $(CFGDIR)/strinput.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/strsubscript.o: $(SRCDIR)/strsubscript.s $(CFGDIR)/strsubscript.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/strtofloat.o: $(SRCDIR)/strtofloat.s $(CFGDIR)/strtofloat.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/subtract.o: $(SRCDIR)/subtract.s $(CFGDIR)/subtract.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/succ.o: $(SRCDIR)/succ.s $(CFGDIR)/succ.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/uint16comp.o: $(SRCDIR)/uint16comp.s $(CFGDIR)/uint16comp.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/uint16mult.o: $(SRCDIR)/uint16mult.s $(CFGDIR)/uint16mult.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/uint32comp.o: $(SRCDIR)/uint32comp.s $(CFGDIR)/uint32comp.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/uint32mult.o: $(SRCDIR)/uint32mult.s $(CFGDIR)/uint32mult.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJTARGETDIR)/writeint.o: $(SRCDIR)/writeint.s $(CFGDIR)/writeint.cfg $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(LIBTARGETDIR)/abs.lib: $(OBJTARGETDIR)/abs.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/abs.cfg $<

$(LIBTARGETDIR)/add.lib: $(OBJTARGETDIR)/add.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/add.cfg $<

$(LIBTARGETDIR)/array.lib: $(OBJTARGETDIR)/array.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/array.cfg $<

$(LIBTARGETDIR)/assign.lib: $(OBJTARGETDIR)/assign.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/assign.cfg $<

$(LIBTARGETDIR)/comp.lib: $(OBJTARGETDIR)/comp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/comp.cfg $<

$(LIBTARGETDIR)/converttypes.lib: $(OBJTARGETDIR)/converttypes.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/converttypes.cfg $<

$(LIBTARGETDIR)/decsp4.lib: $(OBJTARGETDIR)/decsp4.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/decsp4.cfg $<

$(LIBTARGETDIR)/divide.lib: $(OBJTARGETDIR)/divide.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/divide.cfg $<

$(LIBTARGETDIR)/divint.lib: $(OBJTARGETDIR)/divint.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/divint.cfg $<

$(LIBTARGETDIR)/float.lib: $(OBJTARGETDIR)/float.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/float.cfg $<

$(LIBTARGETDIR)/floatabs.lib: $(OBJTARGETDIR)/floatabs.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatabs.cfg $<

$(LIBTARGETDIR)/floatadd.lib: $(OBJTARGETDIR)/floatadd.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatadd.cfg $<

$(LIBTARGETDIR)/floatcomp.lib: $(OBJTARGETDIR)/floatcomp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatcomp.cfg $<

$(LIBTARGETDIR)/floatinput.lib: $(OBJTARGETDIR)/floatinput.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatinput.cfg $<

$(LIBTARGETDIR)/floatdiv.lib: $(OBJTARGETDIR)/floatdiv.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatdiv.cfg $<

$(LIBTARGETDIR)/floatmult.lib: $(OBJTARGETDIR)/floatmult.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatmult.cfg $<

$(LIBTARGETDIR)/floatneg.lib: $(OBJTARGETDIR)/floatneg.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatneg.cfg $<

$(LIBTARGETDIR)/floatnorm.lib: $(OBJTARGETDIR)/floatnorm.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatnorm.cfg $<

$(LIBTARGETDIR)/floatoutput.lib: $(OBJTARGETDIR)/floatoutput.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatoutput.cfg $<

$(LIBTARGETDIR)/floatround.lib: $(OBJTARGETDIR)/floatround.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatround.cfg $<

$(LIBTARGETDIR)/floatsqr.lib: $(OBJTARGETDIR)/floatsqr.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatsqr.cfg $<

$(LIBTARGETDIR)/floatsub.lib: $(OBJTARGETDIR)/floatsub.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatsub.cfg $<

$(LIBTARGETDIR)/floatutil.lib: $(OBJTARGETDIR)/floatutil.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatutil.cfg $<

$(LIBTARGETDIR)/getline.lib: $(OBJTARGETDIR)/getline.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/getline.cfg $<

$(LIBTARGETDIR)/inputbuf.lib: $(OBJTARGETDIR)/inputbuf.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/inputbuf.cfg $<

$(LIBTARGETDIR)/int8.lib: $(OBJTARGETDIR)/int8.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int8.cfg $<

$(LIBTARGETDIR)/int8add.lib: $(OBJTARGETDIR)/int8add.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int8add.cfg $<

$(LIBTARGETDIR)/int8comp.lib: $(OBJTARGETDIR)/int8comp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int8comp.cfg $<

$(LIBTARGETDIR)/int8div.lib: $(OBJTARGETDIR)/int8div.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int8div.cfg $<

$(LIBTARGETDIR)/int8mult.lib: $(OBJTARGETDIR)/int8mult.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int8mult.cfg $<

$(LIBTARGETDIR)/int8sub.lib: $(OBJTARGETDIR)/int8sub.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int8sub.cfg $<

$(LIBTARGETDIR)/int16.lib: $(OBJTARGETDIR)/int16.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int16.cfg $<

$(LIBTARGETDIR)/int16add.lib: $(OBJTARGETDIR)/int16add.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int16add.cfg $<

$(LIBTARGETDIR)/int16comp.lib: $(OBJTARGETDIR)/int16comp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int16comp.cfg $<

$(LIBTARGETDIR)/int16div.lib: $(OBJTARGETDIR)/int16div.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int16div.cfg $<

$(LIBTARGETDIR)/int16mult.lib: $(OBJTARGETDIR)/int16mult.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int16mult.cfg $<

$(LIBTARGETDIR)/int16sub.lib: $(OBJTARGETDIR)/int16sub.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int16sub.cfg $<

$(LIBTARGETDIR)/int32.lib: $(OBJTARGETDIR)/int32.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32.cfg $<

$(LIBTARGETDIR)/int32add.lib: $(OBJTARGETDIR)/int32add.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32add.cfg $<

$(LIBTARGETDIR)/int32comp.lib: $(OBJTARGETDIR)/int32comp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32comp.cfg $<

$(LIBTARGETDIR)/int32div.lib: $(OBJTARGETDIR)/int32div.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32div.cfg $<

$(LIBTARGETDIR)/int32mult.lib: $(OBJTARGETDIR)/int32mult.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32mult.cfg $<

$(LIBTARGETDIR)/int32sqr.lib: $(OBJTARGETDIR)/int32sqr.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32sqr.cfg $<

$(LIBTARGETDIR)/int32sub.lib: $(OBJTARGETDIR)/int32sub.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32sub.cfg $<

$(LIBTARGETDIR)/leftpad.lib: $(OBJTARGETDIR)/leftpad.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/leftpad.cfg $<

$(LIBTARGETDIR)/math.lib: $(OBJTARGETDIR)/math.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/math.cfg $<

$(LIBTARGETDIR)/memcopy.lib: $(OBJTARGETDIR)/memcopy.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/memcopy.cfg $<

$(LIBTARGETDIR)/mod.lib: $(OBJTARGETDIR)/mod.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/mod.cfg $<

$(LIBTARGETDIR)/multiply.lib: $(OBJTARGETDIR)/multiply.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/multiply.cfg $<

$(LIBTARGETDIR)/negate.lib: $(OBJTARGETDIR)/negate.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/negate.cfg $<

$(LIBTARGETDIR)/popax.lib: $(OBJTARGETDIR)/popax.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/popax.cfg $<

$(LIBTARGETDIR)/pred.lib: $(OBJTARGETDIR)/pred.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/pred.cfg $<

$(LIBTARGETDIR)/pusheax.lib: $(OBJTARGETDIR)/pusheax.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/pusheax.cfg $<

$(LIBTARGETDIR)/printz.lib: $(OBJTARGETDIR)/printz.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/printz.cfg $<

$(LIBTARGETDIR)/readfloatfrominput.lib: $(OBJTARGETDIR)/readfloatfrominput.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/readfloatfrominput.cfg $<

$(LIBTARGETDIR)/readint16.lib: $(OBJTARGETDIR)/readint16.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/readint16.cfg $<

$(LIBTARGETDIR)/readint32.lib: $(OBJTARGETDIR)/readint32.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/readint32.cfg $<

$(LIBTARGETDIR)/readintfrominput.lib: $(OBJTARGETDIR)/readintfrominput.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/readintfrominput.cfg $<

$(LIBTARGETDIR)/record.lib: $(OBJTARGETDIR)/record.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/record.cfg $<

$(LIBTARGETDIR)/rtstack.lib: $(OBJTARGETDIR)/rtstack.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/rtstack.cfg $<

$(LIBTARGETDIR)/sqr.lib: $(OBJTARGETDIR)/sqr.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/sqr.cfg $<

$(LIBTARGETDIR)/string.lib: $(OBJTARGETDIR)/string.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/string.cfg $<

$(LIBTARGETDIR)/strassign.lib: $(OBJTARGETDIR)/strassign.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/strassign.cfg $<

$(LIBTARGETDIR)/strconcat.lib: $(OBJTARGETDIR)/strconcat.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/strconcat.cfg $<

$(LIBTARGETDIR)/strconvert.lib: $(OBJTARGETDIR)/strconvert.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/strconvert.cfg $<

$(LIBTARGETDIR)/strinput.lib: $(OBJTARGETDIR)/strinput.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/strinput.cfg $<

$(LIBTARGETDIR)/strsubscript.lib: $(OBJTARGETDIR)/strsubscript.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/strsubscript.cfg $<

$(LIBTARGETDIR)/strtofloat.lib: $(OBJTARGETDIR)/strtofloat.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/strtofloat.cfg $<

$(LIBTARGETDIR)/subtract.lib: $(OBJTARGETDIR)/subtract.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/subtract.cfg $<

$(LIBTARGETDIR)/succ.lib: $(OBJTARGETDIR)/succ.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/succ.cfg $<

$(LIBTARGETDIR)/uint16comp.lib: $(OBJTARGETDIR)/uint16comp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/uint16comp.cfg $<

$(LIBTARGETDIR)/uint16mult.lib: $(OBJTARGETDIR)/uint16mult.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/uint16mult.cfg $<

$(LIBTARGETDIR)/uint32comp.lib: $(OBJTARGETDIR)/uint32comp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/uint32comp.cfg $<

$(LIBTARGETDIR)/uint32mult.lib: $(OBJTARGETDIR)/uint32mult.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/uint32mult.cfg $<

$(LIBTARGETDIR)/writeint.lib: $(OBJTARGETDIR)/writeint.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/writeint.cfg $<

$(LIBFILE): $(LIBS)
	python3 $(MKRUNTIME) $(TARGET)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(LIBS)
	$(RM) $(LIBFILE)
	$(RM) $(BINTARGETDIR)/*
