# Proof-of-concept custom loaders in Linux

This is a proof-of-concept to show different methods to load executables in the Linux kernel with our own loaders / linkers / interpreters.

### Methods

#### 1. binfmt_misc

We use a kernel module called binfmt_misc to register our own binary format in the Linux kernel.

The loader will be called in userspace.

See: https://www.kernel.org/doc/Documentation/binfmt_misc.txt

See: `demo_binfmt_misc` in Makefile

#### 2. ELF Interpreter section (INTERP)

Every dynamically linked ELF executable contains a special section called `.interp`.

In case the Linux kernel sees such a section, I will load the interpreter instead.
Afterwards, it is the task of the interpreter (usually ld-linux.so) to load all dependencies and do the final relocation.

See: `demo_interpreter` in the Makefile

#### 3. Custom kernel module

We use the binfmt subsystem of the Linux kernel to implement our own format.

A good example is the loader for the script she-bangs (`#!/bin/bash` et al):

https://github.com/torvalds/linux/blob/master/fs/binfmt_script.c

### Credits

Steffen Vogel <post@steffenvogel.de>