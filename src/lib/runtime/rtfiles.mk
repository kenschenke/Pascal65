# The runtime files (see mkruntime.py). Include this with RUNTIMEDIR (the
# path to src/lib/runtime) and TARGET set.
#
#   RTABI     the runtime ABI version, RT_ABI_VERSION in asm.inc
#   RTNAMES   the runtime files: the core and the package variants, which
#             codegen links into static programs, and the full runtime,
#             which dynamic programs load (codegen reads its header too)
#   RUNTIME   the core file, which make builds them all for
#   RTWRITE   c1541 arguments that write RTNAMES to a disk image

RTABI := $(shell sed -n 's/^RT_ABI_VERSION *= *\([0-9]*\).*/\1/p' $(RUNTIMEDIR)/../../asminc/asm.inc)
RTNAMES := core$(RTABI) runtime$(RTABI) dynarrays$(RTABI)a
RTNAMES += $(addprefix files$(RTABI),a b)
RTNAMES += $(addprefix trig$(RTABI),a b c d)
RUNTIME = $(RUNTIMEDIR)/bin/$(TARGET)/core$(RTABI)
RTWRITE = $(foreach n,$(RTNAMES),-write $(RUNTIMEDIR)/bin/$(TARGET)/$(n) $(n),prg)
