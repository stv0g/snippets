## Proof-of-concept to show different methods to load executables in the Linux kernel
#
# @copyright	2016 Steffen Vogel
# @license	http://www.gnu.org/licenses/gpl.txt GNU Public License
# @author	Steffen Vogel <post@steffenvogel.de>
# @link		http://www.steffenvogel.de
#########################################################################################

TARGETS = demo-interpreter demo-binfmt_misc proxy proxy-static

# We need to know absolute paths to our interpreters / loaders
MKDIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROXY = $(MKDIR)/proxy

CC = gcc
CFLAGS = -g -std=c11 -fPIC
LDFLAGS =

# We are patching the OS/ABI field of the ELF header
ELF_OSABI_OFFSET = 7
ELF_OSABI = "\\xa1"

# We are registering a new binary format in the kernel
BINFMT_MISC_PATH = /proc/sys/fs/binfmt_misc
BINFMT_MISC_NAME = hermit
BINFMT_MISC_FILE = $(BINFMT_MISC_PATH)/$(BINFMT_MISC_NAME)

.PHONY: all clean binfmt_misc

all: $(TARGETS)

binfmt_misc: $(BINFMT_MISC_PATH)/$(BINFMT_MISC_NAME)

# Register a new binary format within the kernel binfmt subsystem
#  binfmt_misc is a kernel module which allows us to register new formats
#  based on magic numbers and filename extension matching.
#  Loading is then performed by custom interpreters in the userspace.
$(BINFMT_MISC_FILE):
	# Mount binfmt_misc pseudo FS ##########################################################
	test -d $(BINFMT_MISC_PATH) || mount binfmt_misc -t binfmt_misc $(BINFMT_MISC_PATH)

	# Remove old entry #####################################################################
	test -f $(BINFMT_MISC_FILE) && echo -1 > $(BINFMT_MISC_FILE)

	# Register new format ##################################################################
	echo ":$(BINFMT_MISC_NAME):M:$(ELF_OSABI_OFFSET):$(ELF_OSABI)::$(PROXY):" > $(BINFMT_MISC_PATH)/register

	# Test for success and show result #####################################################
	test -f $(BINFMT_MISC_FILE) && cat $(BINFMT_MISC_FILE)

# We have to versions of our demo application:
#
#  1. We use a custom dynamic linker (instead of the usual dynamic linker: ld-linux.so)
#     For some reason our interpreter must be statically linked or we get a segfault.
demo-interpreter: demo.o
	# Link demo_interpreter ################################################################
	$(CC) $(LDFLAGS) -Wl,-dynamic-linker,$(PROXY)-static -o $@ $?

	# Verify ###############################################################################
	readelf -l $@ | grep -A 2 INTERP

# 2. We register a new binary format within the Linux kernel
#    And patch our binary in a way it get's recognized by the new format
#    binfmt_misc succeeds with starting our dynamically linked interpreter "proxy" :-)
demo-binfmt_misc: demo.o $(BINFMT_MISC_FILE)
	# Link demo_binfmt_misc ################################################################
	$(CC) $(LDFLAGS) -o $@ $<

	# Patch OS/ABI field in ELF header to match the binfmt_misc format #####################
	printf $(ELF_OSABI) | dd of=$@ bs=1 seek=$(ELF_OSABI_OFFSET) count=1 conv=notrunc

	# Verify ###############################################################################
	readelf -h $@ | grep "OS/ABI"

# This is the loader / proxy which is executed by the binfmt_misc subsystem or the 1st stage loader "loader"
proxy: proxy.o
	# Link proxy ###########################################################################
	$(CC) $(LDFLAGS) -o $@ $?

proxy-static: proxy.o
	# Link proxy ###########################################################################
	$(CC) $(LDFLAGS) -static -o $@ $?

clean:
	rm -rf $(TARGETS)
	rm -rf *.o
	make -C kernel clean
