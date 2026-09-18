## =====================================================================
##  Portable C project Makefile
##
##  Conventions borrowed from:
##    - Linux kernel Kbuild        : recursive wildcard, V=1 verbosity,
##                                    CROSS_COMPILE/ARCH toolchain prefix,
##                                    "?=" so the caller's environment wins
##    - Yocto (bitbake) recipes    : never hardcode CC/CFLAGS/LDFLAGS -
##                                    the recipe injects them via env/
##                                    make args; DESTDIR + PREFIX install
##    - AOSP Android.mk            : one file per module, immediate (:=)
##                                    expansion for file lists, no implicit
##                                    recursive make
##    - 42 School Norm             : mandatory all / clean / fclean / re
##
##  Drop this file at the project root next to src/ and include/.
## =====================================================================

# ----------------------------------------------------------------------
# Toolchain
# ----------------------------------------------------------------------
# CROSS_COMPILE lets a Yocto recipe or a cross build cross-target this,
# e.g. `make CROSS_COMPILE=arm-poky-linux-gnueabi-` - same spelling the
# kernel build system uses. Left empty, this is a native build.
CROSS_COMPILE   ?=
CC              := $(CROSS_COMPILE)cc
AR              := $(CROSS_COMPILE)ar
RM              := rm -f
MKDIR           := mkdir -p

# ----------------------------------------------------------------------
# Project layout
# ----------------------------------------------------------------------
NAME            := a.out
SRC_DIR         := src
INC_DIR         := include
OBJ_DIR         := obj

SRCS            := $(wildcard $(SRC_DIR)/*.c)
OBJS            := $(SRCS:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)
DEPS            := $(OBJS:.o=.d)

# ----------------------------------------------------------------------
# Compiler / linker flags
# ----------------------------------------------------------------------
# All of these use "?=" or "+=" on purpose, never "=": a Yocto recipe (or
# any caller) that exports CFLAGS/LDFLAGS before invoking make must be
# able to extend or override them, not have them silently clobbered.
CSTD            ?= -std=c99
WARN            := -Wall -Wextra -Werror
CFLAGS          ?= $(CSTD) $(WARN) -g
CPPFLAGS        ?=
CPPFLAGS        += -I$(INC_DIR)
LDFLAGS         ?=
LDLIBS          ?=

# ----------------------------------------------------------------------
# Preprocessor definitions
# ----------------------------------------------------------------------
# Two ways in, both additive so they can be combined:
#
# 1) Environment / command-line variable - space-separated NAME or
#    NAME=VALUE tokens, e.g.:
#      make DEFINES="DEBUG LOG_LEVEL=3"
#      DEFINES="DEBUG" make
DEFINES         ?=
CPPFLAGS        += $(addprefix -D,$(DEFINES))

# 2) Input file - a Kconfig-style key=value file, included if present
#    (not an error if it's missing). Lines look like:
#      CONFIG_FOO=1
#      CONFIG_LOG_LEVEL=3
#    Override its path with `make DOTCONFIG=path/to/file`.
#    NB: the control variable is deliberately named DOTCONFIG, not
#    CONFIG_FILE - anything matching CONFIG_% below is re-exported as a
#    -D flag, so the path variable itself must live outside that
#    namespace or it would leak in as its own bogus define.
DOTCONFIG       ?= .config
-include $(DOTCONFIG)
CONFIG_VARS     := $(filter CONFIG_%,$(.VARIABLES))
CPPFLAGS        += $(foreach v,$(CONFIG_VARS),-D$(v)=$($(v)))

# ----------------------------------------------------------------------
# Build verbosity (Kbuild style: `make V=1` for full command lines)
# ----------------------------------------------------------------------
ifeq ($(V),1)
  Q :=
else
  Q := @
endif

# ----------------------------------------------------------------------
# Install locations (Yocto's do_install stage sets DESTDIR; standard
# GNU PREFIX otherwise defaults to /usr/local)
# ----------------------------------------------------------------------
PREFIX          ?= /usr/local
DESTDIR         ?=
BINDIR          := $(DESTDIR)$(PREFIX)/bin

# ----------------------------------------------------------------------
# Required rules: all, clean, fclean, re
# ----------------------------------------------------------------------
.PHONY: all clean fclean re install uninstall

all: $(NAME)

$(NAME): $(OBJS)
	@echo "LD      $@"
	$(Q)$(CC) $(OBJS) $(LDFLAGS) -o $@ $(LDLIBS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	@echo "CC      $<"
	$(Q)$(CC) $(CFLAGS) $(CPPFLAGS) -MMD -MP -c $< -o $@

$(OBJ_DIR):
	$(Q)$(MKDIR) $@

-include $(DEPS)

clean:
	@echo "CLEAN   $(OBJ_DIR)"
	$(Q)$(RM) -r $(OBJ_DIR)

fclean: clean
	@echo "FCLEAN  $(NAME)"
	$(Q)$(RM) $(NAME)

re: fclean all

install: all
	$(Q)$(MKDIR) $(BINDIR)
	$(Q)install -m 755 $(NAME) $(BINDIR)/$(NAME)

uninstall:
	$(Q)$(RM) $(BINDIR)/$(NAME)

.SUFFIXES: