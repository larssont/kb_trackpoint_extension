#
# Setup
#

# Much faster, but requires OpenScad snapshot
OPENSCAD="/Applications/OpenSCAD Snapshot.app/Contents/MacOS/OpenSCAD" --enable=manifold

# This will work with the stable openscad
#OPENSCAD="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"

#
# Parameters
#

# By how much you want to increase the adapter hole compared to the
# actual TP stem width.
# Sets the parameter `adapter_hole_incr_default`
HOLE_INCR ?= 0

# The height from the pcb to where you want the cap to end.
# Sets the parameter `desired_cap_height`
HEIGHT ?= 0

# How far the TP is mounted BELOW the PCB.
# This should include the thickness of any plastic or electrical tape you use
# to isolate the TP mount.
# Sets the parameter `tp_mounting_distance_default`
MOUNTING_DISTANCE ?= 0

# Thickness of the pcb (1.6mm by default)
# Sets the parameter `pcb_height_default`
PCB_HEIGHT ?= 0

# By how much you want to increase the tip for a tighter cap fit.
# Sets the parameter `tip_width_incr_default`
TIP_INCR ?= 0

#
# Don't change below
#

.DEFAULT_GOAL := help

ifeq ($(HOLE_INCR),0)
  HOLE_INCR_VAL=
  HOLE_INCR_FNAME=
else
  HOLE_INCR_VAL=-D adapter_hole_incr_default=$(HOLE_INCR)
  HOLE_INCR_FNAME=_hw$(HOLE_INCR)
endif

ifeq ($(HEIGHT),0)
  HEIGHT_VAL=
  HEIGHT_FNAME=
else
  HEIGHT_VAL=-D desired_cap_height_default=$(HEIGHT)
  HEIGHT_FNAME=_h$(HEIGHT)
endif

ifeq ($(MOUNTING_DISTANCE),0)
  MOUNTING_DISTANCE_VAL=
  MOUNTING_DISTANCE_FNAME=
else
  MOUNTING_DISTANCE_VAL=-D tp_mounting_distance_default=$(MOUNTING_DISTANCE)
  MOUNTING_DISTANCE_FNAME=_md$(MOUNTING_DISTANCE)
endif

ifeq ($(PCB_HEIGHT),0)
  PCB_HEIGHT_VAL=
  PCB_HEIGHT_FNAME=
else
  PCB_HEIGHT_VAL=-D pcb_height_default=$(PCB_HEIGHT)
  PCB_HEIGHT_FNAME=_pcb$(PCB_HEIGHT)
endif

ifeq ($(TIP_INCR),0)
  TIP_INCR_VAL=
  TIP_INCR_FNAME=
else
  TIP_INCR_VAL=-D tip_width_incr_default=$(TIP_INCR)
  TIP_INCR_FNAME=_t$(TIP_INCR)
endif

PARAMS = $(HEIGHT_VAL) $(MOUNTING_DISTANCE_VAL) $(PCB_HEIGHT_VAL) $(HOLE_INCR_VAL) $(TIP_INCR_VAL)
FNAME_POSTFIX = $(HEIGHT_FNAME)$(MOUNTING_DISTANCE_FNAME)$(PCB_HEIGHT_FNAME)$(HOLE_INCR_FNAME)$(TIP_INCR_FNAME)

# Pathes for combined
COMBINED_STL_ARRAY=[]

# OpenScad options
OPENSCAD_OPTIONS=--export-format binstl
OPENSCAD_CMD=$(OPENSCAD) $(OPENSCAD_OPTIONS)

# Directories
SRC_DIR := src
STL_DIR := stl

# Create targets for files starting with `export_`
EXPORT_SCAD_FILES := $(wildcard $(SRC_DIR)/export_*.scad)

STL_TARGETS := $(patsubst $(SRC_DIR)/export_%.scad,$(STL_DIR)/%$(FNAME_POSTFIX).stl,$(EXPORT_SCAD_FILES))

$(STL_DIR)/%$(FNAME_POSTFIX).stl: $(SRC_DIR)/export_%.scad $(SRC_DIR)/trackpoint_extension.scad
	@echo "Building $@..."
	$(OPENSCAD_CMD) $(PARAMS) --render -o $@ $<
	@echo
	@echo

combined:
	@echo "Building $@..."
	$(eval COMBINED_STL_ARRAY:=$(shell bash -c 'printf "["; for file in "$(STL_DIR)"/*.stl; do if [ "$$file" != "$(STL_DIR)/tp_ext_combined.stl" ] && [ -e "$$file" ]; then printf "\\\"../%s\\\", " "$$file"; fi; done | sed "s/, $$//"; printf "]"'))
	$(OPENSCAD_CMD) $(PARAMS) --render -D stl_array='$(COMBINED_STL_ARRAY)' -o $(STL_DIR)/tp_ext_combined.stl $(SRC_DIR)/stl_combiner.scad
	@echo
	@echo

# Default target
all: $(STL_TARGETS) combined

# Remove generated STL files
clean:
	rm -f $(STL_TARGETS)

# Help target
help: help-text targets

help-text:
	@echo "Help:"
	@echo
	@echo "  You can customize the output using the following parameters with any of the targets below..."
	@echo
	@echo "  To see the target names for the parameters you can run:"
	@echo "    make targets HOLE_INCR=0.2 HEIGHT=10.5"
	@echo
	@echo "  And then to run a target:"
	@echo "    make stl/tp_red_t460s_h10.5_hw0.2.stl HOLE_INCR=0.2 HEIGHT=10.5"
	@echo
	@echo "  The important thing is that the target name and parameters match."
	@echo
	@echo "  Or you can build all targets with:"
	@echo "    make all HOLE_INCR=0.2 HEIGHT=10.5"
	@echo
	@echo "Parameters:"
	@echo
	@echo "  HOLE_INCR=0.2"
	@echo "    By how much you want to increase the adapter hole compared to the actual TP stem width."
	@echo
	@echo "  HEIGHT=10.5"
	@echo "    The height from the pcb to where you want the cap to end."
	@echo
	@echo "  MOUNTING_DISTANCE=1.0"
	@echo "    How far the TP is mounted BELOW the PCB. This should include the thickness of any plastic or electrical tape you use to isolate the TP mount."
	@echo
	@echo "  PCB_HEIGHT=1.6"
	@echo "    Thickness of the pcb."
	@echo
	@echo "  TIP_INCR=0.3"
	@echo "    By how much you want to increase the tip for a tighter cap fit."
	@echo

targets:
	@echo "Available targets:"
	@$(foreach target,$(STL_TARGETS),echo "  $(target)";)
	@echo
