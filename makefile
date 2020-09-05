#!/usr/bin/make -f

title = game
version = 0.01

objlist = init miuchiz domino

AS65 = ca65
LD65 = ld65
CFLAGS65 = -g
objdir = obj/
srcdir = src
imgdir = tilesets

CC = gcc
CFLAGS = -std=gnu99 -Wall -DNDEBUG -O

# Windows needs .exe suffixed to the names of executables; UNIX does
# not.  COMSPEC will be set to the name of the shell on Windows and
# not defined on UNIX.  Also the Windows Python installer puts
# py.exe in the path, but not python3.exe, which confuses MSYS Make.
ifdef COMSPEC
DOTEXE:=.exe
PY:=py
else
DOTEXE:=
PY:=python3
endif

# Pseudo-targets
.PHONY: clean send

send: $(title).dat
	$(PY) tools/FastLoad.py tools/clone.dat tools/flash.dat

#run: $(title).dat
#	$(EMU) $<
all: $(title).dat

$(objdir)/index.txt: makefile
	echo Files produced by build tools go here > $@

clean:
	-rm $(objdir)/*.o $(objdir)/*.s $(objdir)/*.chr

# Rules for code

objlisto = $(foreach o,$(objlist),$(objdir)/$(o).o)
objlistalto = $(foreach o,$(objlistalt),$(objdir)/$(o).o)

map.txt $(title).dat: linker.cfg $(objlisto)
	$(LD65) -o $(title).dat --dbgfile $(title).dbg -m map.txt -C $^
	$(PY) tools/ConvertToMiuchiz.py

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/hardware.inc $(srcdir)/global.inc
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

# Files that depend on .incbin'd files
#$(objdir)/chrram.o: $(objdir)/bggfx.chr $(objdir)/spritegfx.chr

# This is an example of how to call a lookup table generator at
# build time.  mktables.py itself is not included because the demo
# has no music engine, but it's available online at
# http://wiki.nesdev.com/w/index.php/APU_period_table
#$(objdir)/ntscPeriods.s: tools/mktables.py
#	$< period $@

# Rules for CHR RAM

#$(objdir)/%.chr: $(imgdir)/%.png
#	$(PY) tools/pilbmp2nes.py $< $@

#$(objdir)/%16.chr: $(imgdir)/%.png
#	$(PY) tools/pilbmp2nes.py -H 16 $< $@


