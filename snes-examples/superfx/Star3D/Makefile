ifeq ($(strip $(PVSNESLIB_HOME)),)
$(error "Please create an environment variable PVSNESLIB_HOME by following this guide: https://github.com/alekmaul/pvsneslib/wiki/Installation")
endif

export PVSNESLIB_DEBUG=1

# ROMNAME is used in snes_rules file
export ROMNAME := star3d

include ${PVSNESLIB_HOME}/devkitsnes/snes_rules

#---------------------------------------------------------------------------------
# GSU (Super FX) program: snes_rules has no rule for it, since wla-superfx is a
# separate assembler from wla-65816. Assemble it here and feed the resulting
# object into the normal link (it must land in the ROM bank hdr.asm reserves
# for it - see gsu/star3d_gsu.s).
#---------------------------------------------------------------------------------
GSUOBJS := gsu/star3d_gsu.obj
OFILES  += $(GSUOBJS)

gsu/star3d_gsu.obj: gsu/star3d_gsu.s
	@echo Assembling GSU program ... $(notdir $<)
	$(SUPERFX) $(ASFLAGS) -o $@ $<

#---------------------------------------------------------------------------------
.PHONY: all cleanLogs

all: cleanLogs buildWithSummary

buildActual: $(OFILES) $(ROMNAME).sfc

clean: cleanBuildRes cleanRom cleanGfx cleanLogs
