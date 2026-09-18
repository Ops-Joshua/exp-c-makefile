Experimental Makefile template with consideration of Linux, Yocto conventions.
Includes 42 school required target.

# Guideline 1: Toolchain never hardcoded. 
CC := $(CROSS_COMPILE)cc mirrors the kernel's ARCH/CROSS_COMPILE pattern, so make CROSS_COMPILE=arm-poky-linux-gnueabi- retargets it for a Yocto cross build without touching the file.

# Guideline 2: `?=` and `+=`, 
_never_ `=`, on CFLAGS/CPPFLAGS/LDFLAGS. A bitbake recipe exports CC/CFLAGS/LDFLAGS into the environment before invoking make; a flat `=` would silently discard whatever the recipe set. Using ?=/+= means the environment wins and the Makefile only supplies fallbacks.

# Guideline 3: Hide and Seek. User sets verbosity
V=1 verbosity. Same convention as Kbuild - builds default to terse CC file.c / LD name lines, make V=1 shows full command lines. Controlled by one Q := / Q := @ switch.

# Guideline 4: Input options thru DOTCONFIG 
 Preprocessor can be input as command line options or sourced from input file.
