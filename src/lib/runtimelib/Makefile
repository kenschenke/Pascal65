MAKEFLAGS += -r

SRCDIR := src
OBJDIR := obj
BINDIR := bin
CFGDIR := cfg
LIBDIR := lib
LIBCOMMONDIR := ../common
MKRUNTIME := mkruntime.py

LIBNAME := runtime.lib
LIBFILE := $(BINDIR)/$(LIBNAME)
TARGET := mega65
CC65TARGET = c64

ifeq ($(TARGET),mega65)
ASFLAGS = -I ../../asminc -D __MEGA65__
else
ASFLAGS = -I ../../asminc
endif
LDFLAGS =

SOURCES += $(wildcard $(SRCDIR)/*.s)

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))

LIBS := $(addsuffix .lib,$(basename $(addprefix $(LIBDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINDIR) $(OBJDIR) $(LIBDIR) $(LIBFILE)

$(BINDIR):
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

$(LIBDIR):
	mkdir -p $@

# vpath %.s $(SRCDIR)
# $(OBJDIR)/%.o: %.s $(CFGDIR)/%.cfg | $(OBJDIR)
# 	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

###
# vpath %.s $(SRCDIR)
# $(OBJDIR)/%.o: %.s | $(OBJDIR)
# 	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<
###

# vpath %.o $(SRCDIR)
# $(LIBDIR)/$*.lib: %.o | $(LIBDIR)
# 	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/$*.cfg $<

$(OBJDIR)/abs.o: $(SRCDIR)/abs.s $(CFGDIR)/abs.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/add.o: $(SRCDIR)/add.s $(CFGDIR)/add.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/array.o: $(SRCDIR)/array.s $(CFGDIR)/array.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/assign.o: $(SRCDIR)/assign.s $(CFGDIR)/assign.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/comp.o: $(SRCDIR)/comp.s $(CFGDIR)/comp.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/converttypes.o: $(SRCDIR)/converttypes.s $(CFGDIR)/converttypes.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/decsp4.o: $(SRCDIR)/decsp4.s $(CFGDIR)/decsp4.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/divide.o: $(SRCDIR)/divide.s $(CFGDIR)/divide.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/divint.o: $(SRCDIR)/divint.s $(CFGDIR)/divint.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/float.o: $(SRCDIR)/float.s $(CFGDIR)/float.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatabs.o: $(SRCDIR)/floatabs.s $(CFGDIR)/floatabs.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatadd.o: $(SRCDIR)/floatadd.s $(CFGDIR)/floatadd.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatcomp.o: $(SRCDIR)/floatcomp.s $(CFGDIR)/floatcomp.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatdiv.o: $(SRCDIR)/floatdiv.s $(CFGDIR)/floatdiv.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatinput.o: $(SRCDIR)/floatinput.s $(CFGDIR)/floatinput.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatmult.o: $(SRCDIR)/floatmult.s $(CFGDIR)/floatmult.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatneg.o: $(SRCDIR)/floatneg.s $(CFGDIR)/floatneg.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatnorm.o: $(SRCDIR)/floatnorm.s $(CFGDIR)/floatnorm.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatoutput.o: $(SRCDIR)/floatoutput.s $(CFGDIR)/floatoutput.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatround.o: $(SRCDIR)/floatround.s $(CFGDIR)/floatround.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatsqr.o: $(SRCDIR)/floatsqr.s $(CFGDIR)/floatsqr.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatsub.o: $(SRCDIR)/floatsub.s $(CFGDIR)/floatsub.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/floatutil.o: $(SRCDIR)/floatutil.s $(CFGDIR)/floatutil.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/getline.o: $(SRCDIR)/getline.s $(CFGDIR)/getline.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/inputbuf.o: $(SRCDIR)/inputbuf.s $(CFGDIR)/inputbuf.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int8.o: $(SRCDIR)/int8.s $(CFGDIR)/int8.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int8add.o: $(SRCDIR)/int8add.s $(CFGDIR)/int8add.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int8comp.o: $(SRCDIR)/int8comp.s $(CFGDIR)/int8comp.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int8div.o: $(SRCDIR)/int8div.s $(CFGDIR)/int8div.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int8mult.o: $(SRCDIR)/int8mult.s $(CFGDIR)/int8mult.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int8sub.o: $(SRCDIR)/int8sub.s $(CFGDIR)/int8sub.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int16.o: $(SRCDIR)/int16.s $(CFGDIR)/int16.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int16add.o: $(SRCDIR)/int16add.s $(CFGDIR)/int16add.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int16comp.o: $(SRCDIR)/int16comp.s $(CFGDIR)/int16comp.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int16div.o: $(SRCDIR)/int16div.s $(CFGDIR)/int16div.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int16mult.o: $(SRCDIR)/int16mult.s $(CFGDIR)/int16mult.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int16sub.o: $(SRCDIR)/int16sub.s $(CFGDIR)/int16sub.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int32.o: $(SRCDIR)/int32.s $(CFGDIR)/int32.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int32add.o: $(SRCDIR)/int32add.s $(CFGDIR)/int32add.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int32comp.o: $(SRCDIR)/int32comp.s $(CFGDIR)/int32comp.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int32div.o: $(SRCDIR)/int32div.s $(CFGDIR)/int32div.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int32mult.o: $(SRCDIR)/int32mult.s $(CFGDIR)/int32mult.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int32sqr.o: $(SRCDIR)/int32sqr.s $(CFGDIR)/int32sqr.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/int32sub.o: $(SRCDIR)/int32sub.s $(CFGDIR)/int32sub.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/leftpad.o: $(SRCDIR)/leftpad.s $(CFGDIR)/leftpad.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/mod.o: $(SRCDIR)/mod.s $(CFGDIR)/mod.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/math.o: $(SRCDIR)/math.s $(CFGDIR)/math.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/memcopy.o: $(SRCDIR)/memcopy.s $(CFGDIR)/memcopy.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/multiply.o: $(SRCDIR)/multiply.s $(CFGDIR)/multiply.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/negate.o: $(SRCDIR)/negate.s $(CFGDIR)/negate.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/popax.o: $(SRCDIR)/popax.s $(CFGDIR)/popax.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/pred.o: $(SRCDIR)/pred.s $(CFGDIR)/pred.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/pushax.o: $(SRCDIR)/pushax.s $(CFGDIR)/pushax.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/pusheax.o: $(SRCDIR)/pusheax.s $(CFGDIR)/pusheax.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/printz.o: $(SRCDIR)/printz.s $(CFGDIR)/printz.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/readfloatfrominput.o: $(SRCDIR)/readfloatfrominput.s $(CFGDIR)/readfloatfrominput.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/readint16.o: $(SRCDIR)/readint16.s $(CFGDIR)/readint16.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/readint32.o: $(SRCDIR)/readint32.s $(CFGDIR)/readint32.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/readintfrominput.o: $(SRCDIR)/readintfrominput.s $(CFGDIR)/readintfrominput.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/record.o: $(SRCDIR)/record.s $(CFGDIR)/record.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/rtstack.o: $(SRCDIR)/rtstack.s $(CFGDIR)/rtstack.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/sqr.o: $(SRCDIR)/sqr.s $(CFGDIR)/sqr.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/string.o: $(SRCDIR)/string.s $(CFGDIR)/string.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/strtofloat.o: $(SRCDIR)/strtofloat.s $(CFGDIR)/strtofloat.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/subtract.o: $(SRCDIR)/subtract.s $(CFGDIR)/subtract.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/succ.o: $(SRCDIR)/succ.s $(CFGDIR)/succ.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/uint16comp.o: $(SRCDIR)/uint16comp.s $(CFGDIR)/uint16comp.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/uint16mult.o: $(SRCDIR)/uint16mult.s $(CFGDIR)/uint16mult.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/uint32comp.o: $(SRCDIR)/uint32comp.s $(CFGDIR)/uint32comp.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/uint32mult.o: $(SRCDIR)/uint32mult.s $(CFGDIR)/uint32mult.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(OBJDIR)/writeint.o: $(SRCDIR)/writeint.s $(CFGDIR)/writeint.cfg $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(LIBDIR)/abs.lib: $(OBJDIR)/abs.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/abs.cfg $<

$(LIBDIR)/add.lib: $(OBJDIR)/add.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/add.cfg $<

$(LIBDIR)/array.lib: $(OBJDIR)/array.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/array.cfg $<

$(LIBDIR)/assign.lib: $(OBJDIR)/assign.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/assign.cfg $<

$(LIBDIR)/comp.lib: $(OBJDIR)/comp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/comp.cfg $<

$(LIBDIR)/converttypes.lib: $(OBJDIR)/converttypes.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/converttypes.cfg $<

$(LIBDIR)/decsp4.lib: $(OBJDIR)/decsp4.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/decsp4.cfg $<

$(LIBDIR)/divide.lib: $(OBJDIR)/divide.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/divide.cfg $<

$(LIBDIR)/divint.lib: $(OBJDIR)/divint.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/divint.cfg $<

$(LIBDIR)/float.lib: $(OBJDIR)/float.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/float.cfg $<

$(LIBDIR)/floatabs.lib: $(OBJDIR)/floatabs.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatabs.cfg $<

$(LIBDIR)/floatadd.lib: $(OBJDIR)/floatadd.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatadd.cfg $<

$(LIBDIR)/floatcomp.lib: $(OBJDIR)/floatcomp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatcomp.cfg $<

$(LIBDIR)/floatinput.lib: $(OBJDIR)/floatinput.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatinput.cfg $<

$(LIBDIR)/floatdiv.lib: $(OBJDIR)/floatdiv.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatdiv.cfg $<

$(LIBDIR)/floatmult.lib: $(OBJDIR)/floatmult.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatmult.cfg $<

$(LIBDIR)/floatneg.lib: $(OBJDIR)/floatneg.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatneg.cfg $<

$(LIBDIR)/floatnorm.lib: $(OBJDIR)/floatnorm.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatnorm.cfg $<

$(LIBDIR)/floatoutput.lib: $(OBJDIR)/floatoutput.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatoutput.cfg $<

$(LIBDIR)/floatround.lib: $(OBJDIR)/floatround.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatround.cfg $<

$(LIBDIR)/floatsqr.lib: $(OBJDIR)/floatsqr.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatsqr.cfg $<

$(LIBDIR)/floatsub.lib: $(OBJDIR)/floatsub.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatsub.cfg $<

$(LIBDIR)/floatutil.lib: $(OBJDIR)/floatutil.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/floatutil.cfg $<

$(LIBDIR)/getline.lib: $(OBJDIR)/getline.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/getline.cfg $<

$(LIBDIR)/inputbuf.lib: $(OBJDIR)/inputbuf.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/inputbuf.cfg $<

$(LIBDIR)/int8.lib: $(OBJDIR)/int8.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int8.cfg $<

$(LIBDIR)/int8add.lib: $(OBJDIR)/int8add.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int8add.cfg $<

$(LIBDIR)/int8comp.lib: $(OBJDIR)/int8comp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int8comp.cfg $<

$(LIBDIR)/int8div.lib: $(OBJDIR)/int8div.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int8div.cfg $<

$(LIBDIR)/int8mult.lib: $(OBJDIR)/int8mult.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int8mult.cfg $<

$(LIBDIR)/int8sub.lib: $(OBJDIR)/int8sub.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int8sub.cfg $<

$(LIBDIR)/int16.lib: $(OBJDIR)/int16.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int16.cfg $<

$(LIBDIR)/int16add.lib: $(OBJDIR)/int16add.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int16add.cfg $<

$(LIBDIR)/int16comp.lib: $(OBJDIR)/int16comp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int16comp.cfg $<

$(LIBDIR)/int16div.lib: $(OBJDIR)/int16div.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int16div.cfg $<

$(LIBDIR)/int16mult.lib: $(OBJDIR)/int16mult.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int16mult.cfg $<

$(LIBDIR)/int16sub.lib: $(OBJDIR)/int16sub.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int16sub.cfg $<

$(LIBDIR)/int32.lib: $(OBJDIR)/int32.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32.cfg $<

$(LIBDIR)/int32add.lib: $(OBJDIR)/int32add.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32add.cfg $<

$(LIBDIR)/int32comp.lib: $(OBJDIR)/int32comp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32comp.cfg $<

$(LIBDIR)/int32div.lib: $(OBJDIR)/int32div.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32div.cfg $<

$(LIBDIR)/int32mult.lib: $(OBJDIR)/int32mult.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32mult.cfg $<

$(LIBDIR)/int32sqr.lib: $(OBJDIR)/int32sqr.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32sqr.cfg $<

$(LIBDIR)/int32sub.lib: $(OBJDIR)/int32sub.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/int32sub.cfg $<

$(LIBDIR)/leftpad.lib: $(OBJDIR)/leftpad.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/leftpad.cfg $<

$(LIBDIR)/math.lib: $(OBJDIR)/math.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/math.cfg $<

$(LIBDIR)/memcopy.lib: $(OBJDIR)/memcopy.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/memcopy.cfg $<

$(LIBDIR)/mod.lib: $(OBJDIR)/mod.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/mod.cfg $<

$(LIBDIR)/multiply.lib: $(OBJDIR)/multiply.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/multiply.cfg $<

$(LIBDIR)/negate.lib: $(OBJDIR)/negate.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/negate.cfg $<

$(LIBDIR)/popax.lib: $(OBJDIR)/popax.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/popax.cfg $<

$(LIBDIR)/pred.lib: $(OBJDIR)/pred.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/pred.cfg $<

$(LIBDIR)/pushax.lib: $(OBJDIR)/pushax.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/pushax.cfg $<

$(LIBDIR)/pusheax.lib: $(OBJDIR)/pusheax.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/pusheax.cfg $<

$(LIBDIR)/printz.lib: $(OBJDIR)/printz.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/printz.cfg $<

$(LIBDIR)/readfloatfrominput.lib: $(OBJDIR)/readfloatfrominput.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/readfloatfrominput.cfg $<

$(LIBDIR)/readint16.lib: $(OBJDIR)/readint16.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/readint16.cfg $<

$(LIBDIR)/readint32.lib: $(OBJDIR)/readint32.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/readint32.cfg $<

$(LIBDIR)/readintfrominput.lib: $(OBJDIR)/readintfrominput.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/readintfrominput.cfg $<

$(LIBDIR)/record.lib: $(OBJDIR)/record.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/record.cfg $<

$(LIBDIR)/rtstack.lib: $(OBJDIR)/rtstack.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/rtstack.cfg $<

$(LIBDIR)/sqr.lib: $(OBJDIR)/sqr.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/sqr.cfg $<

$(LIBDIR)/string.lib: $(OBJDIR)/string.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/string.cfg $<

$(LIBDIR)/strtofloat.lib: $(OBJDIR)/strtofloat.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/strtofloat.cfg $<

$(LIBDIR)/subtract.lib: $(OBJDIR)/subtract.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/subtract.cfg $<

$(LIBDIR)/succ.lib: $(OBJDIR)/succ.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/succ.cfg $<

$(LIBDIR)/uint16comp.lib: $(OBJDIR)/uint16comp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/uint16comp.cfg $<

$(LIBDIR)/uint16mult.lib: $(OBJDIR)/uint16mult.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/uint16mult.cfg $<

$(LIBDIR)/uint32comp.lib: $(OBJDIR)/uint32comp.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/uint32comp.cfg $<

$(LIBDIR)/uint32mult.lib: $(OBJDIR)/uint32mult.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/uint32mult.cfg $<

$(LIBDIR)/writeint.lib: $(OBJDIR)/writeint.o
	ld65 $(LDFLAGS) -o $@ -C $(CFGDIR)/writeint.cfg $<

###
# $(BINDIR)/$(PROGRAM): $(OBJECTS)
# 	ld65 $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) -C $(CONFIG) $(OBJECTS)
###

$(LIBFILE): $(LIBS)
	python3 $(MKRUNTIME)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(LIBS)
	$(RM) $(LIBFILE)
	$(RM) $(BINDIR)/*
