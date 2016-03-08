MODULE = binfmt_hermit

obj-m += $(MODULE).o

.PHONY: all clean install reload

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

install: all
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules_install

reload: install
	modprobe -r $(MODULE)
	modprobe    $(MODULE)
