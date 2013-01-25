.PHONY: all
all: bootstrap.elf kernel.elf

bootstrap.elf: bootstrap.o bootstrap.ld
	ld -melf_i386 -Tbootstrap.ld -o $@ bootstrap.o

bootstrap.o: bootstrap.asm
	yasm -felf32 -o $@ $^

kernel.elf: kernel.o kernel.ld
	ld -Tkernel.ld -z max-page-size=0x1000 -o $@ kernel.o

kernel.o: kernel.asm
	yasm -felf64 -o $@ $^

.PHONY: clean
clean:
	rm -f *.o *~ bootstrap.elf kernel.elf bootimg/hd.img

.PHONY: install
install:
	(cd bootimg; sudo ./install.sh)
